class Usher
  class Route
    class Variable

      module ProcValidator
        def valid!(val)
          begin
            @validator.call(val)
          rescue Exception => e
            raise ValidationException.new("#{val} does not conform to #{@validator}, root cause #{e.inspect}")
          end
        end
      end

      module CaseEqualsValidator
        def valid!(val)
          @validator === val.to_s or raise(ValidationException.new("#{val} does not conform to #{@validator}"))
        end
      end
      
      attr_reader :type, :name, :validator, :regex_matcher
      attr_accessor :look_ahead, :default_value, :look_ahead_priority
      
      def initialize(name, regex_matcher = nil, validator = nil)
        @name = name.to_s.to_sym
        @validator = validator || regex_matcher
        @regex_matcher = regex_matcher
        
        case @validator
        when nil
          # do nothing
        when Proc
          extend(ProcValidator)
        else
          extend(CaseEqualsValidator)
        end
      end
      private :initialize

      def valid!(val)
      end
      
      def ==(o)
        o && (o.class == self.class && o.name == @name && o.validator == @validator)
      end
      
      class Single < Variable
        def to_s
          ":#{name}"
        end
      end

      class Glob < Variable
        def to_s
          "*#{name}"
        end
      end

      class Greedy < Variable
        def to_s
          "!#{name}"
        end
      end
      
    end
    
  end
end