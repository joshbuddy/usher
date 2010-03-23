class Usher
  module Interface
    class Rack
      # Middleware for using Usher's rack interface to recognize the request, then, pass on to the next application.
      # Values are stored in <tt>env</tt> normally.
      #
      class Middleware

        def initialize(app, router)
          @app = app
          @router = router
        end

        def call(env)
          @router.call(env)
          @app.call(env)
        end

      end
    end
  end
end