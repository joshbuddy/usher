class Usher
  class Route
    class Variable
      attr_reader :type, :name, :validator, :transformer
      
      def initialize(type, name, opts = {})
        @type = type
        @name = :"#{name}"
        @validator = opts[:validator]
        @transformer = opts[:transformer]
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