class Usher
  module Interface
    class Rack
      module Route
        # add("/index.html").redirect("/")
        def redirect(path, status = 302)
          @destination = lambda do
            response = Rack::Response.new
            response.redirect(path, status)
            response.finish
          end
          return self
        end
      end
    end
  end
end
