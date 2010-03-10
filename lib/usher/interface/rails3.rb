class Usher
  module Interface
    class Rails3
      
      def initialize
        @router = Usher.new(:request_methods => [:request_method, :host, :port, :scheme], :generator => Usher::Util::Generators::URL.new)
      end
      
      def add_route(app, conditions = {}, defaults = {}, name = nil)
        
      end
      
      def call(env)
      end
      
      def url(args = nil)
      end
      
    end
  end
end
