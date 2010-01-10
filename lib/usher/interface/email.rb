class Usher
  module Interface
    class Email

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
          response.path.route.destination.call(response.params_as_hash)
        end
      end

    end
  end
end
