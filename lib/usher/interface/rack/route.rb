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
          to { |env|
            params = env[Usher::Interface::Rack::ENV_KEY_PARAMS]
            response = ::Rack::Response.new
            response.redirect(eval(%|"#{path}"|), status)
            response.finish
          }
          self
        end
        
        # Serves either files from a directory, or a single static file.
        def serves_static_from(root)
          if File.directory?(root)
            match_partially!
            @destination = ::Rack::File.new(root)
          else
            @destination = proc{|env| env['PATH_INFO'] = File.basename(root); ::Rack::File.new(File.dirname(root)).call(env)}
          end
        end
      end
    end
  end
end