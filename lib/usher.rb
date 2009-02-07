require 'set'
require 'strscan'

module ActionController
  module Routing
    
    class RouteSet
      attr_accessor :tree, :configuration_file
      
      SymbolArraySorter = proc {|a,b| a.to_s <=> b.to_s}
      
      class Mapper #:doc:
        def initialize(set) #:nodoc:
          @set = set
        end

        # Create an unnamed route with the provided +path+ and +options+. See
        # ActionController::Routing for an introduction to routes.
        def connect(path, options = {})
          @set.add_route(path, options)
        end

        # Creates a named route called "root" for matching the root level request.
        def root(options = {})
          if options.is_a?(Symbol)
            if source_route = @set.named_routes.routes[options]
              options = source_route.defaults.merge({ :conditions => source_route.conditions })
            end
          end
          named_route("root", '', options)
        end

        def named_route(name, path, options = {}) #:nodoc:
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
        require @configuration_file
      end
      
      def draw
        reset!
        yield Mapper.new(self)
        install_helpers
      end
      
      def reset!
        @tree = Node.root
        @names = {}
        @param_lookups = {}
        @param_keys = []
        @module ||= Module.new
        @module.instance_methods.each do |selector|
          @module.class_eval { remove_method selector }
        end
      end
      
      def initialize
        reset!
      end

      def add_named_route(name, path, options = {})
        @names[name] = add_route(path, options)
      end

      def add_route(path, *args)
        options = args.last.is_a?(Hash) ? args.last : {}
        route = Route.new(Route.path_to_route_parts(path), options)
        @tree.add(route)
        @param_keys.push(*route.dynamic_keys)
        sorted_keys = route.dynamic_keys.sort(&SymbolArraySorter)
        @param_lookups[sorted_keys] = @param_lookups.key?(sorted_keys) ? nil : route
        route
      end

      def recognize(request)
        path = Route.path_to_route_parts(request.path)
        (route, params_list) = @tree.find(path)
        params = route.options
        params_list.each do |pair|
          params[pair[0]] = pair[1]
        end
        request.path_parameters = params.with_indifferent_access
        "#{params[:controller].camelize}Controller".constantize
      end

      def install_helpers(destinations = [ActionController::Base, ActionView::Base], regenerate_code = false)
        #*_url and hash_for_*_url
        Array(destinations).each do |d| d.module_eval { include Helpers } 
          @names.keys.each do |name|
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
          generate_url(@param_lookups[options.keys.sort(&SymbolArraySorter)], options)
        else
          raise
        end
      end

      def generate_url(route, params)
        route = @names[route] if route.is_a?(Symbol)
        
        param_list = case params
        when Hash
          params = route.options.merge(params)
          route.dynamic_keys.collect{|k| params[k]}
        when Array
          params
        else
          Array(params)
        end
        
        route.path.collect {|p| p.is_a?(Route::Variable) ? param_list.shift : p.to_s}.to_s
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
            @depth
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
        
        def terminates?
          @terminates
        end
        
        def find_parent(clazz)
          @parent && @parent.value.is_a?(clazz) ? @parent : @parent.find_parent(clazz)
        end
        
        def current_route
          route = [@value]
          p = self
          while not (p = p.parent).nil?
            route.unshift(@value)
          end
          route
        end
        
        def add(route, path = route.path)
          
          unless path.size == 0
            key = path.first
            key = nil if key.is_a?(Route::Variable)
            
            unless @lookup.key?(key)
              @lookup[key] = Node.new(self, path.first)
            end
            target_node = @lookup[key]
            target_node.terminates = route if path.size == 1
            target_node.add(route, path[1..(path.size-1)])
          end
        end
        
        def find(path, params = [])
          return [terminates, params] if terminates? && path.size.zero?
          part = path.shift
          
          if @lookup[part]
            @lookup[part].find(path, params)
          elsif @lookup[nil]
            next_part = @lookup[nil]
            if next_part.value.is_a?(Route::Variable)
              case next_part.value.type
              when :*
                params << [next_part.value.name, []]
                params.last.last << part unless next_part.is_a?(Route::Seperator)
              when :':'
                params << [next_part.value.name, part]
              end
            end
            @lookup[nil].find(path, params)
          elsif find_parent(Route::Variable).value.type == :*
            params.last.last << part unless part.is_a?(Route::Seperator)
            find(path, params)
          else
            raise
          end
        end
        
      end
      
      class Route
        attr_accessor :path, :options
        
        def self.path_to_route_parts(path)
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
          parts
        end
        
        attr_reader :dynamic_parts, :dynamic_map, :dynamic_keys, :dynamic_indicies
        
        def initialize(path, options = {})
          @path = path
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
          Slash = Seperator.new(:'/')
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
        
      end

    end

    UsherRoutes = RouteSet.new

  end
end