class Usher
  module Interface
    class RackInterface
      module Route
        # add("/index.html").redirect("/")
        def redirect(path, status = 302)
          lambda do
            response = Rack::Response.new
            response.redirect(path, status)
            response.finish
          end
        end
      end
    end
  end
end
