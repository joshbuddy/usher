class Usher
  module Interface
    class Rack
      # Middleware for using Usher's rack interface to recognize the request, then, pass on to the next application.
      # Values are stored in `env` normally. The details of that storage is in the Rack interface itself.
      # @see Usher::Interface::Rack
      class Middleware
        
        # @param app [#call] Application to call next
        # @param router [Usher::Interface::Rack] The router call first before calling the next application
        def initialize(app, router)
          @app = app
          @router = router
        end

        # @param env [Hash] The environment hash
        # @return [#each] The application's return
        def call(env)
          @router.call(env)
          @app.call(env)
        end

      end
    end
  end
end