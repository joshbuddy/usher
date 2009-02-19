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
      attr_reader :tree, :named_routes, :route_count
      attr_accessor :configuration_file
      
      SymbolArraySorter = proc {|a,b| a.hash <=> b.hash}
      
      def reload
        reset!
        if @configuration_file
          load @configuration_file
        else
          add_route ":controller/:action/:id"
        end
      end
      
      def load_routes!
        reload
      end
      
      def empty?
        @route_count.zero?
      end

      def draw
        reset!
        yield Mapper.new(self)
        install_helpers
      end
      
      def reset!
        @tree = Node.root
        @named_routes = {}
        @module ||= Module.new
        @module.instance_methods.each do |selector|
          @module.class_eval { remove_method selector }
        end
        @controller_action_route_added = false
        @controller_route_added = false
        @route_count = 0
        Grapher.instance.reset!
      end
      alias clear! reset!
      
      def initialize(mode = :rails)
        @mode = mode
        reset!
      end

      def add_named_route(name, path, options = {})
        @named_routes[name.to_sym] = add_route(path, options)
      end

      def add_route(path, options = {})
        if !@controller_action_route_added && path =~ %r{^/?:controller/:action/:id$}
          add_route('/:controller/:action', options)
          @controller_action_route_added = true 
        end

        if !@controller_route_added && path =~ %r{^/?:controller/:action$}
          add_route('/:controller', options.merge({:action => 'index'}))
          @controller_route_added = true 
        end

        route = Route.new(path, options)
        @tree.add(route)
        Grapher.instance.add_route(route)
        @route_count += 1
        route
      end

      def recognize(request)
        path = Route.path_to_route_parts(request.path, request.method)
        (route, params_list) = @tree.find(path)
        request.path_parameters = (params_list && !params_list.empty? ? route.params.merge(Hash[*(params_list.first)]) : route.params).with_indifferent_access
        "#{request.path_parameters[:controller].camelize}Controller".constantize
      end

      def install_helpers(destinations = [ActionController::Base, ActionView::Base], regenerate_code = false)
        #*_url and hash_for_*_url
        Array(destinations).each do |d| d.module_eval { include Helpers } 
          @named_routes.keys.each do |name|
            @module.module_eval <<-end_eval # We use module_eval to avoid leaks
              def #{name}_url(options = {})
                ActionController::Routing::UsherRoutes.generate(options, {}, :generate, :#{name})
              end
            end_eval
          end
          d.__send__(:include, @module)
        end
      end
      
      def route_for_options(options)
        Grapher.instance.find_matching_route(options)
      end
      
      def generate(options, recall = {}, method = :generate, route_name = nil)
        route = if(route_name)
          @named_routes[route_name]
        else
          merged_options = options
          merged_options[:controller] = recall[:controller] unless options.key?(:controller)
          unless options.key?(:action)
            options[:action] = nil
          end
          route_for_options(merged_options)
        end
        case method
        when :extra_keys
          (route && route.dynamic_keys) || []
        when :generate
          merged_options ||= recall.merge(options)
          generate_url(route, merged_options)
        else
          raise "no route found for #{options.inspect}"
        end
      end

      def extra_keys(options, recall={})
        generate(options, recall, :extra_keys)
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
          params_hash = params
          route.dynamic_parts.collect{|k| params_hash.delete(k.name)}
        when Array
          params
        else
          Array(params)
        end

        path = ""
        
        route.path.each do |p|
          case p
          when Route::Variable:
            case p.type
            when :*
              path << '/' << param_list.shift * '/'
            else
              (dp = param_list.shift) && path << '/' << dp.to_s
            end
          when Route::Seperator:
            # do nothing
          when Route::Method:
            # do nothing
          else
            path << '/' << p.to_s
          end
        end
        unless params_hash.blank?
          has_query = path[??]
          params_hash.each do |k,v|
            case v
            when Array
              v.each do |v_part|
                path << (has_query ? '&' : has_query = true && '?')
                path << CGI.escape("#{k.to_s}[]")
                path << '='
                path << CGI.escape(v_part.to_s)
              end
            else
              path << (has_query ? '&' : has_query = true && '?')
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