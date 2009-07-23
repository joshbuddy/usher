class Usher
  module Interface
    class EmailInterface
      
      def initialize(&blk)
        @routes = Usher.new(:delimiters => ['@', '-', '.'], :valid_regex => '[\+a-zA-Z0-9]+')
        instance_eval(&blk) if blk
      end
      
      def for(path, &block)
        @routes.add_route(path).to(block)
      end

      def reset!
        @routes.reset!
      end

      def act(email)
        response = @routes.recognize(email, email)
        if response.path
          response.path.route.destination.call(response.params.inject({}){|h,(k,v)| h[k]=v.to_s; h })
        end
      end

    end
  end
end