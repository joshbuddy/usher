class Usher
  # Array of delimiters with convenience methods.
  class Delimiters < Array

    attr_reader :unescaped
    
    # Creates a list of delimiters
    # @param ary [Array<String>] delimters to use
    def initialize(ary)
      super ary
      @unescaped = self.map do |delimiter|
        (delimiter[0] == ?\\) ? delimiter[1..-1] : delimiter
      end
    end
  
    # Finds the first occurrance of a delimiter in an array
    # @param array [Array<String>] Array to search through
    # @return [nil, String] The delimiter matched, or nil if none was found.
    def first_in(array)
      array.find { |e| e if unescaped.any? { |delimiter| delimiter == e } }
    end

    # The regular expression to find the delimiters.
    # @return [Regexp] The regular expression
    def regexp
      @regexp ||= Regexp.new("(#{unescaped.collect{|d| Regexp.quote(d)}.join('|')})")
    end
    
    # The regular expression expressed as a character class.
    # @return [String] The regular expression as a string.
    def regexp_char_class
      @regexp_char_class ||= collect{|d| Regexp.quote(d)}.join
    end
    
  end
end