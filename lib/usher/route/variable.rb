class Usher
  class Route
    class Variable
      attr_reader :type, :name, :validator, :regex_matcher
      attr_accessor :look_ahead, :default_value
      
      def initialize(name, regex_matcher = nil, validator = nil)
        @name = name.to_s.to_sym
        @validator = validator
        @regex_matcher = regex_matcher
      end
      private :initialize
      
      def valid!(val)
        case @validator
        when Proc
          begin
            @validator.call(val)
          rescue Exception => e
            raise ValidationException.new("#{val} does not conform to #{@g}, root cause #{e.inspect}")
          end
        else
          @validator === val or raise(ValidationException.new("#{val} does not conform to #{@validator}, root cause #{e.inspect}"))
        end if @validator
      end
      
      def ==(o)
        o && (o.class == self.class && o.name == @name && o.validator == @validator)
      end
    end
    
    class SingleVariable < Variable
      def to_s
        ":#{name}"
      end
    end
    
    class GlobVariable < Variable
      def to_s
        "*#{name}"
      end
    end
    
    GreedyVariable = Class.new(Variable)
    
  end
end