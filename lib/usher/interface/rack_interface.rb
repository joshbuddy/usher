require 'rack'

class Usher
  module Interface
    class RackInterface
      
      def initialize(&blk)
        @router = Usher.new(:request_methods => [:method, :host, :port, :scheme], :generator => Usher::Util::Generators::URL.new)
        instance_eval(&blk) if blk
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
        env['usher.params'] ||= {}
        response = @router.recognize(request = Rack::Request.new(env), request.path_info)
        if response.nil?
          body = "No route found"
          headers = {"Content-Type" => "text/plain", "Content-Length" => body.length.to_s}
          [404, headers, [body]]
        else
          params = response.path.route.default_values || {}
          response.params.each{ |hk| params[hk.first] = hk.last}
          
          # consume the path_info to the script_name response.remaining_path
          env["SCRIPT_NAME"] << response.matched_path   || ""
          env["PATH_INFO"] = response.remaining_path    || ""
                    
          env['usher.params'].merge!(params)
          
          response.path.route.destination.call(env)
        end
      end

      def generate(route, params = nil, options = nil)
        @usher.generator.generate(route, params, options)
      end

    end
  end
end
