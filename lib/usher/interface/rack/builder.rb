class Usher
  module Interface
    class Rack
      # Replacement for <tt>Rack::Builder</tt> which using Usher to map requests instead of a simple Hash.
      # As well, add convenience methods for the request methods.
      #
      class Builder < ::Rack::Builder
        def initialize(&block)
          @usher = Usher::Interface::Rack.new
          super
        end

        def map(path, options = nil, &block)
          @usher.add(path, options).to(&block)
          @ins << @usher unless @ins.last == @usher
        end

        # it returns route, and because you may want to work with the route,
        # for example give it a name, we returns the route with GET request
        def get(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "HEAD"}), &block)
          self.map(path, options.merge!(:conditions => {:request_method => "GET"}), &block)
        end

        def post(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "POST"}), &block)
        end

        def put(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "PUT"}), &block)
        end

        def delete(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "DELETE"}), &block)
        end
      end
    end
  end
end