class Usher
  module Interface
    class Rack
      # Route specific for Rack with redirection support built in.
      class Route < Usher::Route
        
        # Redirect route to some other path. 
        def redirect(path, status = 302)
          unless (300..399).include?(status)
            raise ArgumentError, "Status has to be an integer between 300 and 399"
          end
          @destination = lambda do |env|
            params = env[Usher::Interface::Rack::ENV_KEY_PARAMS]
            response = ::Rack::Response.new
            response.redirect(eval(%|"#{path}"|), status)
            response.finish
          end
          self
        end
        
        def static_from(root)
          match_partially!
          @destination = ::Rack::File.new(root)
        end
      end
    end
  end
end