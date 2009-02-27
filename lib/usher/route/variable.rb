class Usher
  class Route
    class Variable
      attr_reader :type, :name, :validator
      def initialize(type, name, validator = nil)
        @type = type
        @name = :"#{name}"
        @validator = validator
      end

      def to_s
        "#{type}#{name}"
      end
  
      def ==(o)
        o && (o.type == @type && o.name == @name && o.validator == @validator)
      end
    end
  end
end