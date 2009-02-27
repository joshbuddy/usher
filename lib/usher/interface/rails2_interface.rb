$:.unshift File.dirname(__FILE__)

require 'rails2_interface/mapper'

class Usher
  module Interface
    class Rails2Interface
      
      attr_reader :usher
      attr_accessor :configuration_file

      def initialize
        reset!
      end
      
      def reset!
        @usher ||= Usher.new
        @module ||= Module.new
        @module.instance_methods.each do |selector|
          @module.class_eval { remove_method selector }
        end
        @controller_action_route_added = false
        @controller_route_added = false
        @usher.reset!
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

        options[:action] = 'index' unless options[:action]
        route = @usher.add_route(path, options)
        route.paths.each do |p|
          raise unless p.dynamic_set.include?(:controller) || route.params.include?(:controller)
        end
        route
      end
      
      def recognize(request)
        (path, params_list) = @usher.recognize(request)
        params = params_list.inject({}){|h,(k,v)| h[k]=v; h }
        request.path_parameters = (params_list.empty? ? path.route.params : path.route.params.merge(params)).with_indifferent_access
        "#{request.path_parameters[:controller].camelize}Controller".constantize
      end
      
      def add_named_route(name, route, options = {})
        @usher.add_route(route, options).name(name)
      end
        
      def route_count
        @usher.route_count
      end  
      
      def empty?
        @usher.route_count.zero?
      end
      
      def generate(options, recall = {}, method = :generate, route_name = nil)
        route = if(route_name)
          @usher.named_routes[route_name]
        else
          merged_options = options
          merged_options[:controller] = recall[:controller] unless options.key?(:controller)
          unless options.key?(:action)
            options[:action] = nil
          end
          route_for_options(merged_options)
        end
        case method
        when :generate
          merged_options ||= recall.merge(options)
          generate_url(route, merged_options)
        else
          raise "method #{method} not recognized"
        end
      end
      
      def generate_url(route, params)
        @usher.generate_url(route, params)
      end
      
      def route_for_options(options)
        @usher.route_for_options(options)
      end
      
      def named_routes
        @usher.named_routes
      end

      def reload
        @usher.reset!
        if @configuration_file
          Kernel.load(@configuration_file)
        else
          @usher.add_route ":controller/:action/:id"
        end
      end

      def load_routes!
        reload
      end

      def draw
        reset!
        yield Mapper.new(self)
        install_helpers
      end

      def install_helpers(destinations = [ActionController::Base, ActionView::Base], regenerate_code = false)
        #*_url and hash_for_*_url
        Array(destinations).each do |d| d.module_eval { include Helpers } 
          @usher.named_routes.keys.each do |name|
            @module.module_eval <<-end_eval # We use module_eval to avoid leaks
              def #{name}_url(options = {})
                ActionController::Routing::UsherRoutes.generate(options, {}, :generate, :#{name})
              end
            end_eval
          end
          d.__send__(:include, @module)
        end
      end
      
    end
  end
end
