$:.unshift File.dirname(__FILE__)
require 'strscan'
require 'set'
require 'route_set/mapper'
require 'route_set/node'
require 'route_set/route'
require 'route_set/grapher'

module ActionController
  module Routing
    
    class RouteSet
      attr_reader :tree, :named_routes
      attr_accessor :configuration_file
      
      SymbolArraySorter = proc {|a,b| a.hash <=> b.hash}
      
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
        Grapher.instance.reset!
      end
      
      def initialize
        reset!
      end

      def add_named_route(name, path, options = {})
        @named_routes[name.to_sym] = add_route(path, options)
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
        Grapher.instance.add_route(route)
        route
      end

      def recognize(request)
        path = Route.path_to_route_parts(request.path, :request_method => request.method)
        (route, params_list) = @tree.find(path)
        params = route.options
        params_list.each do |pair|
          tester = route.options[pair[0]] || (route.options[:requirements] && route.options[:requirements][pair[0]])
          raise "#{pair[0]}=#{pair[1]} does not conform to #{tester} for route #{route.original_path}" unless tester.nil? || tester === pair[1]
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
      
      def route_for_options(options)
        Grapher.instance.find_matching_route(options)
      end

      def generate(options, recall = {}, method = :generate)
        case method
        when :extra_keys
          route_for_options(recall.merge(options)).dynamic_keys
        when :generate
          generate_url(route_for_options(recall.merge(options)), options)
        else
          raise
        end
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
        params_hash = {}
        param_list = case params
        when Hash
          params_hash = params.dup
          route.dynamic_keys.collect{|k| route.options[k] || params_hash.delete(k)}
        when Array
          params
        else
          Array(params)
        end
        
        #delete out nonsense
        params_hash.delete(:conditions)

        path = ""
        
        route.path.each do |p| 
          path << case p
          when Route::Variable: param_list.shift.to_s
          when Route::Method:   ''
          else                  p.to_s
          end
        end
        unless params_hash.blank?
          has_query = path[??]
          params_hash.each do |k,v|
            path << (has_query ? '&' : has_query = true && '?')
            case v
            when Array
              v.each do |v_part|
                path << CGI.escape("#{k.to_s}[]")
                path << '='
                path << CGI.escape(v_part.to_s)
              end
            else
              path << CGI.escape(k.to_s)
              path << '='
              path << CGI.escape(v.to_s)
            end
          end
        end
        path
      end

    end

    UsherRoutes = RouteSet.new

  end
end