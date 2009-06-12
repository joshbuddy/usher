$:.unshift File.dirname(__FILE__)

require 'rack'
require 'rack_interface/route'

class Usher
  module Interface
    class RackInterface
      
      RequestMethods = [:request_method, :host, :port, :scheme]
      Request = Struct.new(:path, *RequestMethods)
      
      attr_accessor :routes
      
      def initialize(fallback = nil, &blk)
        @fallback = fallback
        @routes = Usher.new(:request_methods => RequestMethods)
        @generator = Usher::Generators::URL.new(@routes)
        instance_eval(&blk) if blk
      end
      
      def add(path, options = nil)
        @routes.add_route(path, options)
      end

      def reset!
        @routes.reset!
      end

      def call(env)
        if response = @routes.recognize(Rack::Request.new(env))
          params = {}
          response.params.each{ |hk| p hk; params[hk.first] = hk.last}
          env['usher.params'] = params
          response.path.route.destination.call(env)
        elsif @fallback
          fallback.call(env)
        end
      end

      def generate(route, params = nil, options = nil)
        @generator.generate(route, params, options)
      end

    end
  end
end