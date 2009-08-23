require 'rack'

class Usher
  module Interface
    class RackInterface
      
      attr_accessor :routes
      
      def initialize(&blk)
        @routes = Usher.new(:request_methods => [:method, :host, :port, :scheme])
        @generator = Usher::Util::Generators::URL.new(@routes)
        instance_eval(&blk) if blk
      end
      
      def add(path, options = nil)
        match_partially = false
        if path =~ /(.*?)\*$/
          path, match_partially = $1, true
        end
        
        route = @routes.add_route(path, options)
        
        route.match_partially! if match_partially
        route
      end

      def reset!
        @routes.reset!
      end

      def call(env)
        response = @routes.recognize(Rack::Request.new(env))
        if response.nil?
          body = "No route found"
          headers = {"Content-Type" => "text/plain", "Content-Length" => body.length.to_s}
          [404, headers, [body]]
        else
          params = {}
          response.params.each{ |hk| params[hk.first] = hk.last}
          env['usher.params'] = params
          response.path.route.destination.call(env)
        end
      end

      def generate(route, params = nil, options = nil)
        @generator.generate(route, params, options)
      end

    end
  end
end
