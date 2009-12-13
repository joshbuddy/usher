class Usher
  class Delimiters < Array

    attr_reader :unescaped
  
    def initialize(ary)
      super ary
      @unescaped = self.map do |delimiter|
        (delimiter[0] == ?\\) ? delimiter[1..-1] : delimiter
      end
    end
  
    def first_in(array)
      # TODO: should we optimize this O(n*m)? hash or modified or KNP or at leaset sort + b-search. But they are so short

      array.each do |element|
        return element if self.unescaped.any? { |delimiter| delimiter == element }
      end
      nil    
    end

    # TODO: Delimiters#regex and so on  
  end
end