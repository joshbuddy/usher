require 'rack'
require File.join('usher', 'interface', 'rack', 'route')
require File.join('usher', 'interface', 'rack', 'middleware')
require File.join('usher', 'interface', 'rack', 'builder')

class Usher
  module Interface
    class Rack
      
      ENV_KEY_RESPONSE       = 'usher.response'.freeze
      ENV_KEY_PARAMS         = 'usher.params'.freeze
      ENV_KEY_DEFAULT_ROUTER = 'usher.router'.freeze

      attr_reader :router, :router_key
      attr_accessor :redirect_on_trailing_delimiters

      # Constructor for Rack interface for Usher. 
      # <tt>app</tt> - the default application to route to if no matching route is found. The default is a 404 response.
      # <tt>options</tt> - options to configure the router
      # * <tt>use_destinations</tt> - option to disable using the destinations passed into routes. (Default <tt>true</tt>)
      # * <tt>router_key</tt> - Key in which to put router into env. (Default <tt>usher.router</tt>)
      # * <tt>request_methods</tt> - Request methods on <tt>Rack::Request</tt> to use in determining recognition. (Default <tt>[:request_method, :host, :port, :scheme]</tt>)
      # * <tt>generator</tt> - Route generator to use. (Default <tt>Usher::Util::Generators::URL.new</tt>)
      # * <tt>allow_identical_variable_names</tt> - Option to prevent routes with identical variable names to be added. eg, /:variable/:variable would raise an exception if this option is not enabled. (Default <tt>false</tt>)
      def initialize(options = {}, &blk)
        @_app = options[:default_app] || proc{|env| ::Rack::Response.new("Not Found", 404).finish }
        @use_destinations = options.key?(:use_destinations) ? options.delete(:use_destinations) : true
        @router_key = options.delete(:router_key) || ENV_KEY_DEFAULT_ROUTER
        request_methods = options.delete(:request_methods) || [:request_method, :host, :port, :scheme]
        generator = options.delete(:generator) || Usher::Util::Generators::URL.new
        allow_identical_variable_names = options.key?(:allow_identical_variable_names) ? options[:allow_identical_variable_names] : false
        self.redirect_on_trailing_delimiters = options.key?(:redirect_on_trailing_delimiters) ? options.delete(:redirect_on_trailing_delimiters) : false
        if redirect_on_trailing_delimiters
          options[:ignore_trailing_delimiters] = true
        end
        usher_options = {:request_methods => request_methods, :generator => generator, :allow_identical_variable_names => allow_identical_variable_names, :detailed_failure => true}
        usher_options.merge!(options)
        @router = Usher.new(usher_options)
        @router.route_class = Rack::Route

        instance_eval(&blk) if blk
      end
      
      # Returns whether the route set has use_destinations? enabled.
      def use_destinations?
        @use_destinations
      end

      # Creates a deep copy of the current route set.
      def dup
        new_one = super
        original = self
        new_one.instance_eval do
          @router = router.dup
        end
        new_one
      end
      
      # Adds a route to the route set with a `path` and optional `options`.
      # See <tt>Usher#add_route</tt> for more details about the format of the route and options accepted here.
      def add(path, options = nil)
        @router.add_route(path, options)
      end
      alias_method :path, :add

      # Sets the default application when route matching is unsuccessful. Accepts either an application `app` or a block to call.
      #
      # default { |env| ... }
      # default DefaultApp
      def default(app = nil, &block)
        @_app = app ? app : block
      end

      # shortcuts for adding routes for HTTP methods, for example:
      # add("/url", :conditions => {:request_method => "POST"}})
      # is the same as:
      # post("/url")

      # it returns route, and because you may want to work with the route,
      # for example give it a name, we returns the route with GET request

      # Convenience method for adding a route that only matches request method `GET`.
      def only_get(path, options = {})
        add(path, options.merge!(:conditions => {:request_method => ["GET"]}))
      end

      # Convenience method for adding a route that only matches request methods `GET` and `HEAD`.
      def get(path, options = {})
        add(path, options.merge!(:conditions => {:request_method => ["HEAD", "GET"]}))
      end

      # Convenience method for adding a route that only matches request method `POST`.
      def post(path, options = {})
        add(path, options.merge!(:conditions => {:request_method => "POST"}))
      end

      # Convenience method for adding a route that only matches request method `PUT`.
      def put(path, options = {})
        add(path, options.merge!(:conditions => {:request_method => "PUT"}))
      end

      # Convenience method for adding a route that only matches request method `DELETE`.
      def delete(path, options = {})
        add(path, options.merge!(:conditions => {:request_method => "DELETE"}))
      end

      def parent_route=(route)
        @router.parent_route = route
      end

      def parent_route
        @router.parent_route
      end

      def reset!
        @router.reset!
      end

      def call(env)
        env[router_key] = self
        request = ::Rack::Request.new(env)
        response = @router.recognize(request, request.path_info)
        if response.succeeded? && redirect_on_trailing_delimiters and response.only_trailing_delimiters and (request.get? || request.head?)
          response = ::Rack::Response.new
          response.redirect(request.path_info[0, request.path_info.size - 1], 302)
          response.finish
        else
          after_match(request, response) if response.succeeded?
          determine_respondant(response).call(env)
        end
      end

      def generate(route, options = nil)
        @router.generator.generate(route, options)
      end

      # Allows a hook to be placed for sub classes to make use of between matching
      # and calling the application
      #
      # @api plugin
      def after_match(request, response)
        params = response.path.route.default_values ? response.path.route.default_values.merge(response.params_as_hash) : response.params_as_hash

        request.env[ENV_KEY_RESPONSE] ||= []
        request.env[ENV_KEY_RESPONSE] << response

        request.env[ENV_KEY_PARAMS] ?
          request.env[ENV_KEY_PARAMS].merge!(params) :
          (request.env[ENV_KEY_PARAMS] = params)

        # consume the path_info to the script_name
        # response.remaining_path
        consume_path!(request, response) if response.partial_match?
      end

      # Determines which application to respond with.
      #
      #  Within the request when determine respondant is called
      #  If there is a matching route to an application, that
      #  application is called, Otherwise the middleware application is called.
      #
      # @api private
      def determine_respondant(response)
        usable_response = response.succeeded? && use_destinations? && response && response.destination
        if usable_response && response.destination.respond_to?(:call)
          response.destination
        elsif usable_response && response.destination.respond_to?(:args) && response.destination.args.first.respond_to?(:call)
          response.args.first
        elsif !response.succeeded? && response.request_method?
          rack_response = ::Rack::Response.new("Method Not Allowed", 405)
          rack_response['Allow'] = response.acceptable_responses_only_strings.join(", ")
          proc { |env| rack_response.finish }
        else
          _app
        end
      end

      # Consume the path from path_info to script_name
      def consume_path!(request, response)
        request.env["SCRIPT_NAME"] = (request.env["SCRIPT_NAME"] + response.matched_path)
        request.env["PATH_INFO"] = response.remaining_path || ""
      end

      def default_app
        _app
      end

      private
      attr_reader :_app

    end
  end
end
