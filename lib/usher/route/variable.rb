class Usher
  class Route
    class Variable
      attr_reader :type, :name, :validator, :transformer, :regex_matcher
      attr_accessor :look_ahead, :globs_capture_separators
      
      def initialize(type, name, validator = nil, transformer = nil, regex_matcher = nil, globs_capture_separators = false)
        @type = type
        @name = :"#{name}"
        @validator = validator
        @transformer = transformer
        @regex_matcher = regex_matcher
        @globs_capture_separators = globs_capture_separators
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