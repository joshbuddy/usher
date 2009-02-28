class Usher
  class Route
    class Urgent
  
      attr_reader :type, :value
  
      def initialize(type, value)
        @type = type
        @value = value
      end
  
    end
  end
end