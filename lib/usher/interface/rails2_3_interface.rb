$:.unshift File.dirname(__FILE__)

class Usher
  module Interface
    class Rails2_3Interface
      
      attr_reader :configuration_files
      
      def named_routes
        @router.named_routes
      end
      
      def add_named_route(name, route, options = {})
        route = @router.add_route(route, options)
        route.name = name
      end

      def add_route(path, options = {})
        if !@controller_action_route_added && path =~ %r{^/?:controller/:action/:id$}
          add_route('/:controller/:action', options.dup)
          @controller_action_route_added = true 
        end

        if !@controller_route_added && path =~ %r{^/?:controller/:action$}
          add_route('/:controller', options.merge({:action => 'index'}))
          @controller_route_added = true 
        end
        
        options[:action] = 'index' unless options[:action]

        path[0, 0] = '/' unless path[0] == ?/
        route = @router.add_route(path, options).to(options)
        raise "your route must include a controller" unless route.paths.first.dynamic_keys.include?(:controller) || route.destination.include?(:controller)
        route
      end
      
      def initialize
        @router = Usher.new
        @configuration_files = []
        reset!
      end
      
      def add_configuration_file(file)
        @configuration_files << file
      end
      
      def reload!
        if configuration_files.any?
          configuration_files.each { |config| load(config) }
        else
          add_route ":controller/:action/:id"
        end
        
      end
      alias_method :reload, :reload!

      def routes
        @router.routes
      end

      def call(env)
        request = ActionController::Request.new(env)
        app = recognize(request)
        app.call(env).to_a
      end
      
      def recognize(request)
        response = @router.recognize(request)
        request.path_parameters = response.path.route.destination.with_indifferent_access
        response.params.each { |pair| request.path_parameters[pair.first] = pair.last }
        "#{request.path_parameters[:controller].camelize}Controller".constantize
      end
      
      def reset!
        @router.reset!
        @module ||= Module.new
        @configuration_files.clear
      end
      
      def draw
        reset!
        yield ActionController::Routing::RouteSet::Mapper.new(self)
        install_helpers
      end
      
      def install_helpers(destinations = [ActionController::Base, ActionView::Base], regenerate_code = false)
        #*_url and hash_for_*_url
        Array(destinations).each do |d| d.module_eval { include Helpers } 
          @router.named_routes.keys.each do |name|
            @module.module_eval <<-end_eval # We use module_eval to avoid leaks
              def #{name}_url(options = {})
                ActionController::Routing::UsherRoutes.generate(options, {}, :generate, :#{name})
              end
            end_eval
          end
          d.__send__(:include, @module)
        end
      end
      
      class RailsRouteInterface
        
        def initialize(router)
          @router = router
        end
        
      end
      
    end
  end
end