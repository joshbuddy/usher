class Usher
  module Interface
    class Rack
      # Replacement for {Rack::Builder} which using Usher to map requests instead of a simple Hash.
      # As well, add convenience methods for the request methods.
      class Builder < ::Rack::Builder
        def initialize(&block)
          @usher = Usher::Interface::Rack.new
          super
        end
        
        # Maps a path to a block.
        # @param path [String] Path to map to.
        # @param options [Hash] Options for added path.
        # @see Usher#add_route
        def map(path, options = nil, &block)
          @usher.add(path, options).to(&block)
          @ins << @usher unless @ins.last == @usher
        end

        # Maps a path with request methods `HEAD` and `GET` to a block.
        # @param path [String] Path to map to.
        # @param options [Hash] Options for added path.
        # @see Usher#add_route
        def get(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "HEAD"}), &block)
          self.map(path, options.merge!(:conditions => {:request_method => "GET"}), &block)
        end

        # Maps a path with request methods `POST` to a block.
        # @param path [String] Path to map to.
        # @param options [Hash] Options for added path.
        # @see Usher#add_route
        def post(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "POST"}), &block)
        end

        # Maps a path with request methods `PUT` to a block.
        # @param path [String] Path to map to.
        # @param options [Hash] Options for added path.
        # @see Usher#add_route
        def put(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "PUT"}), &block)
        end

        # Maps a path with request methods `DELETE` to a block.
        # @param path [String] Path to map to.
        # @param options [Hash] Options for added path.
        # @see Usher#add_route
        def delete(path, options = nil, &block)
          self.map(path, options.merge!(:conditions => {:request_method => "DELETE"}), &block)
        end
      end
    end
  end
end