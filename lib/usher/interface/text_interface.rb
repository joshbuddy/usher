class Usher
  module Interface
    class TextInterface
      
      def initialize(&blk)
        @usher = Usher.new(:delimiters => [' '])
        instance_eval(&blk) if blk
      end
      
      def on(text, &blk)
        @usher.add_route(text).to(:block => blk, :arg_type => :array)
      end
      
      def on_with_hash(text, &blk)
        @usher.add_route(text).to(:block => blk, :arg_type => :hash)
      end
      
      def run(text)
        response = @usher.recognize_path(text.strip)
        if response
          case response.path.route.destination[:arg_type]
          when :hash
            response.path.route.destination[:block].call(response.params.inject({}){|h,(k,v)| h[k]=v; h })
          when :array
            response.path.route.destination[:block].call(*response.params.collect{|p| p.last})
          end
        else
          nil
        end
      end

    end
  end
end