require 'set'
require 'strscan'

module ActionController
  module Routing
    
    class RouteSet
      attr_reader :tree, :named_routes
      attr_accessor :configuration_file
      
      SymbolArraySorter = proc {|a,b| a.hash <=> b.hash}
      
      class Mapper #:doc:
        def initialize(set) #:nodoc:
          @set = set
        end
      
        def connect(path, options = {})
          @set.add_route(path, options)
        end
      
        def root(options = {})
          if options.is_a?(Symbol)
            if source_route = @set.named_routes[options]
              options = source_route.options.merge({ :conditions => source_route.conditions })
            end
          end
          named_route(:root, '/', options)
        end
      
        def named_route(name, path, options = {})
          @set.add_named_route(name, path, options)
        end
      
        def namespace(name, options = {}, &block)
          if options[:namespace]
            with_options({:path_prefix => "#{options.delete(:path_prefix)}/#{name}", :name_prefix => "#{options.delete(:name_prefix)}#{name}_", :namespace => "#{options.delete(:namespace)}#{name}/" }.merge(options), &block)
          else
            with_options({:path_prefix => name, :name_prefix => "#{name}_", :namespace => "#{name}/" }.merge(options), &block)
          end
        end
        
        def method_missing(route_name, *args, &proc) #:nodoc:
          super unless args.length >= 1 && proc.nil?
          @set.add_named_route(route_name, *args)
        end
      end
      
      def reload
        reset!
        load @configuration_file
      end
      
      def draw
        reset!
        yield Mapper.new(self)
        install_helpers
      end
      
      def reset!
        @tree = Node.root
        @named_routes = {}
        @param_lookups = {}
        @significant_keys = []
        @module ||= Module.new
        @module.instance_methods.each do |selector|
          @module.class_eval { remove_method selector }
        end
      end
      
      def initialize
        reset!
      end

      def add_named_route(name, path, options = {})
        @named_routes[name] = add_route(path, options)
      end

      def add_route(path, *args)
        options = args.extract_options!
        conditions = options.delete(:conditions)
        request_method = conditions && conditions.delete(:method)
        route = Route.new(Route.path_to_route_parts(path, :request_method => request_method), path, options.merge({:conditions => conditions}))
        @tree.add(route)
        @significant_keys.push(*route.dynamic_keys)
        @significant_keys.uniq!
        sorted_keys = route.dynamic_keys.sort(&SymbolArraySorter)
        @param_lookups[sorted_keys] = @param_lookups.key?(sorted_keys) ? nil : route
        route
      end

      def recognize(request)
        path = Route.path_to_route_parts(request.path, :request_method => request.method)
        (route, params_list) = @tree.find(path)
        params = route.options
        params_list.each do |pair|
          tester = route.options[pair[0]] || (route.options[:requirements] && route.options[:requirements][pair[0]])
          raise "#{pair[0]}=#{pair[1]} does not conform to #{tester} for route #{route.original_path}" unless !tester || tester === pair[1]
          params[pair[0]] = pair[1]
        end
        request.path_parameters = params.with_indifferent_access
        "#{params[:controller].camelize}Controller".constantize
      end

      def install_helpers(destinations = [ActionController::Base, ActionView::Base], regenerate_code = false)
        #*_url and hash_for_*_url
        Array(destinations).each do |d| d.module_eval { include Helpers } 
          @named_routes.keys.each do |name|
            @module.module_eval <<-end_eval # We use module_eval to avoid leaks
              def #{name}_url(options = {})
                ActionController::Routing::UsherRoutes.generate_url(:#{name}, options)
              end
            end_eval
          end
          d.__send__(:include, @module)
        end
      end
      
      def generate(options, recall = {}, method = :generate)
        case method
        when :generate
          generate_url(route_for_options(recall.merge(options)), options)
        else
          raise
        end
      end

      def route_for_options(options)
        @param_lookups[(options.keys & @significant_keys).sort(&SymbolArraySorter)]
      end

      def generate_url(route, params)
        route = case route
        when Symbol
          @named_routes[route]
        when nil
          route_for_options(params)
        else
          route
        end
        
        param_list = case params
        when Hash
          params = route.options.merge(params)
          route.dynamic_keys.collect{|k| params[k]}
        when Array
          params
        else
          Array(params)
        end
        
        route.path.delete_if{|p| p.is_a?(Route::Method)}.collect {|p| p.is_a?(Route::Variable) ? param_list.shift : p.to_s}.to_s
        
        
      end

      class Node
        attr_reader :value, :parent, :lookup
        attr_accessor :terminates
        
        def depth
          unless @depth
            @depth = 0
            p = self
            while not (p = p.parent).nil?
              @depth += 1
            end
          end
          @depth
        end
        
        def self.root
          self.new(nil, nil)
        end
        
        def initialize(parent, value)
          @parent = parent
          @value = value
          @lookup = Hash.new
        end
        
        def has_globber?
          if @has_globber.nil?
            @has_globber = find_parent{|p| p.value && p.value.is_a?(Route::Variable)}
            p @has_globber
          end
          @has_globber
        end
        
        def terminates?
          @terminates
        end
        
        def find_parent(&blk)
          if @parent.nil?
            nil
          elsif yield @parent
            @parent
          else #keep searching
            @parent.find_parent(&blk)
          end
        end
        
        def add(route, path = route.path)
          unless path.size == 0
            key = path.first
            key = nil if key.is_a?(Route::Variable)
            
            unless target_node = @lookup[key]
              target_node = @lookup[key] = Node.new(self, path.first)
              
            end
            @lookup[Route::Method::Any] = target_node if path.first.is_a?(Route::Method)
            
            if path.size == 1
              target_node.terminates = route
              target_node.add(route, [])
            else
              target_node.add(route, path[1..(path.size-1)])
            end
          end
        end
        
        def find(path, params = [])
          return [terminates, params] if terminates? && path.size.zero?
          part = path.shift
          
          if next_part = @lookup[part]
            next_part.find(path, params)
          elsif part.is_a?(Route::Method) && next_part = @lookup[Route::Method::Any]
            next_part.find(path, params)
          elsif next_part = @lookup[nil]
            if next_part.value.is_a?(Route::Variable)
              case next_part.value.type
              when :*
                params << [next_part.value.name, []]
                params.last.last << part unless next_part.is_a?(Route::Seperator)
              when :':'
                params << [next_part.value.name, part]
              end
            end
            next_part.find(path, params)
          elsif has_globber? && p = find_parent{|p| !p.is_a?(Route::Seperator)} && p.value.is_a?(Route::Variable) && p.value.type == :*
            params.last.last << part unless part.is_a?(Route::Seperator)
            find(path, params)
          else
            raise "did not recognize #{part}"
          end
        end
        
      end
      
      class Route
        attr_reader :dynamic_parts, :dynamic_map, :dynamic_keys, :dynamic_indicies, :path, :options, :original_path
        
        def self.path_to_route_parts(path, *args)
          options = args.extract_options!
          path.insert(0, '/') unless path[0] == ?/
          ss = StringScanner.new(path)
          parts = []
          while (part = ss.scan(/([:\*]?[0-9a-z_]+|\/|\.)/))
            parts << case part[0]
            when ?:
              Variable.new(:':', part[1..(path.size-1)])
            when ?*
              Variable.new(:'*', part[1..(path.size-1)])
            when ?.
              raise unless part.size == 1
              Seperator::Dot
            when ?/
              raise unless part.size == 1
              Seperator::Slash
            else
              part
            end
          end
          
          parts << Method.for(options[:request_method])
          
          parts
        end
        
        
        def initialize(path, original_path, options = {})
          @path = path
          @original_path = original_path
          @options = options
          @dynamic_parts = @path.select{|p| p.is_a?(Variable)}
          @dynamic_indicies = []
          @path.each_index{|i| @dynamic_indicies << i if @path[i].is_a?(Variable)}
          @dynamic_map = {}
          @dynamic_keys = []
          @dynamic_parts.each{|p| @dynamic_map[@dynamic_keys << p.name] = p }
          raise "must include controller" unless @dynamic_keys.include?(:controller) || options.include?(:controller)
        end
        
        class Seperator
          private
          def initialize(sep)
            @sep = sep
            @sep_to_s = sep.to_s
          end
          
          public
          def to_s
            @sep_to_s
          end
          
          Dot = Seperator.new(:'.')
          Slash = Seperator.new(:/)
        end
        
        class Variable
          attr_reader :type, :name
          def initialize(type, name)
            @type = type
            @name = :"#{name}"
          end
          
          def to_s
            "#{type}#{name}"
          end
        end

        class Method
          private
          attr_reader :name
          def initialize(name)
            @name = name
          end
          
          public
          def self.for(name)
            case name
            when :get:    Get
            when :post:   Post
            when :put:    Put
            when :delete: Delete
            else          Any
            end
          end
          
          def matches(request)
            self == Any || request.method.downcase.to_sym == name
          end
          
          Get = Method.new(:get)
          Post = Method.new(:post)
          Put = Method.new(:put)
          Delete = Method.new(:delete)
          Any = Method.new(:*)
          
        end
        
      end

    end

    UsherRoutes = RouteSet.new

  end
end