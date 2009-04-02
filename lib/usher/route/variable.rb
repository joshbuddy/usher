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
      
      def transform!(val)
        return val unless @transformer

        case @transformer
        when Proc
          @transformer.call(val)
        when Symbol
          val.send(@transformer)
        end
      rescue Exception => e
        raise ValidationException.new("#{val} could not be successfully transformed by #{@transformer}, root cause #{e.inspect}")
      end

      def valid!(val)
        case @validator
        when Proc
          @validator.call(val)
        else
          @validator === val or raise
        end if @validator
      rescue Exception => e
        raise ValidationException.new("#{val} does not conform to #{@validator}, root cause #{e.inspect}")
      end
  
      def ==(o)
        o && (o.type == @type && o.name == @name && o.validator == @validator)
      end
    end
  end
end