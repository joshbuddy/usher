class Usher
  module Interface
    class Rails3
      
      attr_reader :router
      
      def initialize
        @router = Usher.new(:request_methods => [:request_method, :host, :port, :scheme], :generator => Usher::Util::Generators::URL.new)
      end
      
      # Builder method to add a route to the set
      #
      # <tt>app</tt>:: A valid Rack app to call if the conditions are met.
      # <tt>conditions</tt>:: A hash of conditions to match against.
      #                       Conditions may be expressed as strings or
      #                       regexps to match against.
      # <tt>defaults</tt>:: A hash of values that always gets merged in
      # <tt>name</tt>:: Symbol identifier for the route used with named
      #                 route generations
      def add_route(app, conditions = {}, defaults = {}, name = nil)
        route = router.add_route(conditions.delete(:path_info), :conditions => conditions, :defaults => defaults)
        route.name(name) if name
        route.to(app)
      end
      
      def call(env)
        request = ::Rack::Request.new(env)
        response = router.recognize(request, request.path_info)
        if response
          response.destination.call(env)
        else
          ::Rack::Response.new("No route found", 404).finish
        end
      end
      
      # Generates a url from Rack env and identifiers or significant keys.
      #
      # To generate a url by named route, pass the name in as a `Symbol`.
      #   url(env, :dashboard) # => "/dashboard"
      #
      # Additional parameters can be passed in as a hash
      #   url(env, :people, :id => "1") # => "/people/1"
      #
      # If no name route is given, it will fall back to a slower
      # generation search.
      #   url(env, :controller => "people", :action => "show", :id => "1")
      #     # => "/people/1"
      def url(env, *args)
      end
      
      def reset!
        router.reset!
      end
      
    end
  end
end
