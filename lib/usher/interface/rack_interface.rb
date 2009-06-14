class Usher
  module Interface
    class RackInterface
      
      RequestMethods = [:method, :host, :port, :scheme]
      Request = Struct.new(:path, *RequestMethods)
      
      attr_accessor :routes
      
      def initialize(&blk)
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
        response = @routes.recognize(Request.new(env['REQUEST_URI'], env['REQUEST_METHOD'].downcase, env['HTTP_HOST'], env['SERVER_PORT'].to_i, env['rack.url_scheme']))
        params = {}
        response.params.each{ |hk| params[hk.first] = hk.last}
        env['usher.params'] = params
        response.path.route.destination.call(env)
      end

      def generate(route, params = nil, options = nil)
        @generator.generate(route, params, options)
      end

    end
  end
end