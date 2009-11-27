class Usher
  class Route
    # add("/index.html").redirect("/")
    def redirect(path, status = 302)
      unless (300..399).include?(status)
        raise ArgumentError, "Status has to be an integer between 300 and 399"
      end
      @destination = lambda do |env|
        response = Rack::Response.new
        response.redirect(path, status)
        response.finish
      end
      return self
    end
  end
end
