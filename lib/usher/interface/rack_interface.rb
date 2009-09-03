require 'rack'

class Usher
  module Interface
    class RackInterface

      attr_reader :router
      attr_accessor :app

      DEFAULT_APPLICATION = lambda do |env|
        Rack::Response.new("No route found", 404).finish
      end

      class Builder < Rack::Builder

        def initialize(&block)
          @usher = Usher::Interface::RackInterface.new
          super
        end

        def map(path, options = nil, &block)
          @usher.add(path, options).to(&block)
          @ins << @usher unless @ins.last == @usher
        end

      end

      def initialize(app = nil, &blk)
        @app = app || DEFAULT_APPLICATION
        @router = Usher.new(:request_methods => [:request_method, :host, :port, :scheme], :generator => Usher::Util::Generators::URL.new)
        instance_eval(&blk) if blk
      end

      def dup
        new_one = super
        original = self
        new_one.instance_eval do
          @router = router.dup
        end
        new_one
      end

      def add(path, options = nil)
        @router.add_route(path, options)
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
        response = @router.recognize(request = Rack::Request.new(env), request.path_info)
        after_match(env, response) if response
        determine_respondant(response).call(env)
      end

      def generate(route, params = nil, options = nil)
        @usher.generator.generate(route, params, options)
      end

      # Allows a hook to be placed for sub classes to make use of between matching
      # and calling the application
      #
      # @api plugin
      def after_match(env, response)
        env['usher.params'] ||= {}
        params = response.path.route.default_values || {}
        response.params.each{|hk| params[hk.first] = hk.last}
        env['usher.params'].merge!(params)

        # consume the path_info to the script_name response.remaining_path
        env["SCRIPT_NAME"] << response.matched_path   || ""
        env["PATH_INFO"] = response.remaining_path    || ""
      end

      # Determines which application to respond with.
      #
      #  Within the request when determine respondant is called
      #  If there is a matching route to an application, that
      #  application is called, Otherwise the middleware application is called.
      #
      # @api private
      def determine_respondant(response)
        return app if response.nil?
        respondant = response.path.route.destination
        respondant = app unless respondant.respond_to?(:call)
        respondant
      end
    end
  end
end
