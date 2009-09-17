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

        def get(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "GET"}), &block)
        end

        def post(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "POST"}), &block)
        end

        def put(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "PUT"}), &block)
        end

        def delete(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "DELETE"}), &block)
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

      # shortcuts for adding routes for HTTP methods, for example:
      # add("/url", :conditions => {:request_method => "POST"}})
      # is the same as:
      # post("/url")
      #
      # if you need more complex setup, use method add directly, for example:
      # add("/url", :conditions => {:request_method => ["POST", "PUT"]}})
      def get(path, options = {})
        self.add(path, options.merge!(:conditions => {:request_method => "GET"}))
      end

      def post(path, options = {})
        self.add(path, options.merge!(:conditions => {:request_method => "POST"}))
      end

      def put(path, options = {})
        self.add(path, options.merge!(:conditions => {:request_method => "PUT"}))
      end

      def delete(path, options = {})
        self.add(path, options.merge!(:conditions => {:request_method => "DELETE"}))
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

      def generate(route, options = nil)
        @router.generator.generate(route, options)
      end

      # Allows a hook to be placed for sub classes to make use of between matching
      # and calling the application
      #
      # @api plugin
      def after_match(env, response)
        params = response.path.route.default_values ?
          response.path.route.default_values.merge(Hash[response.params]) :
          Hash[response.params]
        
        env['usher.params'] ?
          env['usher.params'].merge!(params) :
          env['usher.params'] = params
        
        # consume the path_info to the script_name
        # response.remaining_path
        consume_path!(env, response) if response.partial_match?
      end

      # Determines which application to respond with.
      #
      #  Within the request when determine respondant is called
      #  If there is a matching route to an application, that
      #  application is called, Otherwise the middleware application is called.
      #
      # @api private
      def determine_respondant(response)
        unless response
          app
        else
          respondant = response.path.route.destination
          respondant = app unless respondant.respond_to?(:call)
          respondant
        end
      end

      # Consume the path from path_info to script_name
      def consume_path!(env, response)
        env["SCRIPT_NAME"] = (env["SCRIPT_NAME"] + response.matched_path)   || ""
        env["PATH_INFO"] = response.remaining_path    || ""
      end
    end
  end
end
