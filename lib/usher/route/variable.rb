class Usher
  class Route
    class Variable
      attr_reader :type, :name, :validator, :regex_matcher
      attr_accessor :look_ahead, :globs_capture_separators, :default_value
      
      def initialize(type, name, validator = nil, regex_matcher = nil, globs_capture_separators = false)
        @type = type
        @name = :"#{name}"
        @validator = validator
        @regex_matcher = regex_matcher
        @globs_capture_separators = globs_capture_separators
      end

      def to_s
        "#{type}#{name}"
      end
      
      def greedy?
        type == :'!'
      end
      
      def valid!(val)
        case @validator
        when Proc
          begin
            @validator.call(val)
          rescue Exception => e
            raise ValidationException.new("#{val} does not conform to #{@validator}, root cause #{e.inspect}")
          end
        else
          @validator === val or raise(ValidationException.new("#{val} does not conform to #{@validator}, root cause #{e.inspect}"))
        end if @validator
      end
      
      def ==(o)
        o && (o.type == @type && o.name == @name && o.validator == @validator)
      end
    end
  end
end