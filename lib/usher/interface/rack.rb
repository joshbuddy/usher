require "rack"
require File.join(File.dirname(__FILE__), 'rack', 'route')

class Usher
  module Interface
    class Rack
      class Builder < ::Rack::Builder
        def initialize(&block)
          @usher = Usher::Interface::Rack.new
          super
        end

        def map(path, options = nil, &block)
          @usher.add(path, options).to(&block)
          @ins << @usher unless @ins.last == @usher
        end

        # it returns route, and because you may want to work with the route,
        # for example give it a name, we returns the route with GET request
        def get(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "HEAD"}), &block)
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

      attr_reader :router

      def initialize(app = nil, &blk)
        @_app = app || lambda { |env| ::Rack::Response.new("No route found", 404).finish }
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
      alias_method :path, :add
      
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
      def get(path, options = {})
        self.add(path, options.merge!(:conditions => {:request_method => ["HEAD", "GET"]}))
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
        request = ::Rack::Request.new(env)
        response = @router.recognize(request, request.path_info)
        after_match(request, response) if response
        determine_respondant(response).call(env)
      end

      def generate(route, options = nil)
        @router.generator.generate(route, options)
      end

      # Allows a hook to be placed for sub classes to make use of between matching
      # and calling the application
      #
      # @api plugin
      def after_match(request, response)
        params = response.path.route.default_values ?
          response.path.route.default_values.merge(Hash[*response.params.flatten]) :
          Hash[*response.params.flatten]
        
        request.env['usher.params'] ?
          request.env['usher.params'].merge!(params) :
          (request.env['usher.params'] = params)
        
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
        response && response.destination || _app
      end

      # Consume the path from path_info to script_name
      def consume_path!(request, response)
        request.env["SCRIPT_NAME"] = (request.env["SCRIPT_NAME"] + response.matched_path)   || ""
        request.env["PATH_INFO"] = response.remaining_path    || ""
      end
      
      def default_app
        _app
      end
      
      private
      attr_reader :_app
      
    end
  end
end
