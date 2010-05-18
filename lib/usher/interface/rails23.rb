class Usher
  module Interface
    class Rails23

      attr_reader :configuration_files

      def named_routes
        @router.named_routes
      end

      def add_named_route(name, route, options = {})
        add_route(route, options).name(name)
      end

      def add_route(path, options = {})
        path.gsub!(/(\..*?(?!\)))$/, '(\1)')
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

        raise "your route must include a controller" unless (route.paths.first.dynamic_keys && route.paths.first.dynamic_keys.include?(:controller)) || route.destination.include?(:controller)
        route
      end

      def initialize
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

      def route_count
        routes.size
      end

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
        request.path_parameters.merge!(response.destination)
        request.path_parameters.merge!(response.params_as_hash)
        "#{request.path_parameters[:controller].camelize}Controller".constantize
      end

      def reset!(options={})
        options[:generator] = options[:generator] || Usher::Util::Generators::URL.new
        options[:request_methods] = options[:request_methods] || [:protocol, :domain, :port, :query_string, :remote_ip, :user_agent, :referer, :method, :subdomains]
        @router = Usher.new(options)
        @configuration_files = []
        @module ||= Module.new
        @controller_route_added = false
        @controller_action_route_added = false
      end

      def draw(options={})
        reset!(options)
        yield ActionController::Routing::RouteSet::Mapper.new(self)
        install_helpers
      end

      def install_helpers(destinations = [ActionController::Base, ActionView::Base], regenerate_code = false)
        #*_url and hash_for_*_url
        Array(destinations).each do |d| d.module_eval { include Helpers }
          @router.named_routes.keys.each do |name|
            @module.module_eval <<-end_eval # We use module_eval to avoid leaks
              def #{name}_url(*args)
                UsherRailsRouter.generate(args, {}, :generate, :#{name})
              end
              def #{name}_path(*args)
                UsherRailsRouter.generate(args, {}, :generate, :#{name})
              end
            end_eval
          end
          d.__send__(:include, @module)
          @router.named_routes.instance_eval "
            def helpers
              { }
            end
          "
          unless @module.const_defined?(:UsherRailsRouter)
            @module.const_set(:UsherRailsRouter, self)
          end
          
          @router.named_routes.helpers.__send__(:extend, @module)
        end
      end

      def generate(args, recall = {}, method = :generate, route_name = nil)
        if args.is_a?(Hash)
          options = args
          args = nil
        else
          args = Array(args)
          options = args.last.is_a?(Hash) ? args.pop : {}
        end
          
        route = if route_name
          @router.named_routes[route_name]
        else
          merged_options = options
          merged_options[:controller] = recall[:controller] unless options.key?(:controller)
          unless options.key?(:action)
            options[:action] = ''
          end
          path_for_options(merged_options)
        end
        case method
          when :generate
            merged_options ||= recall.merge(options)
            url = generate_url(route, args ? args << merged_options : merged_options)
            url.slice!(-1) if url[-1] == ?/
            url
          else
            raise "method #{method} not recognized"
        end
      end

      def generate_url(route, params)
        @router.generator.generate(route, params)
      end

      def path_for_options(options)
        @router.path_for_options(options)
      end

    end
  end
end
