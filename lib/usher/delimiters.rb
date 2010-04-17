class Usher
  # Array of delimiters with convenience methods.
  class Delimiters < Array

    attr_reader :unescaped
  
    def initialize(ary)
      super ary
      @unescaped = self.map do |delimiter|
        (delimiter[0] == ?\\) ? delimiter[1..-1] : delimiter
      end
    end
  
    def first_in(array)
      array.find { |e| e if unescaped.any? { |delimiter| delimiter == e } }
    end

    def regexp
      @regexp ||= Regexp.new("(#{unescaped.collect{|d| Regexp.quote(d)}.join('|')})")
    end
    
    def regexp_char_class
      @regexp_char_class ||= collect{|d| Regexp.quote(d)}.join
    end
    
  end
end