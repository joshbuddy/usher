class Usher
  class Route
    class RequestMethod
  
      attr_reader :type, :value
  
      def initialize(type, value)
        @type = type
        @value = value
      end
      
      def hash
        type.hash + value.hash
      end
      
      def eql?(o)
        o.is_a?(Http) && o.type == type && o.value == value
      end
    end
  end
end