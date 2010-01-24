class Usher
  class Splitter

    def self.for_delimiters(delimiters_array)
      delimiters = Delimiters.new(delimiters_array)
      delimiters_array.any?{|d| d.size > 1} ?
        MultiCharacterSplitterInstance.new(delimiters) :
        SingleCharacterSplitterInstance.new(delimiters)
    end

    class SingleCharacterSplitterInstance
    
      attr_reader :url_split_regex
    
      def initialize(delimiters)
        @url_split_regex = Regexp.new("[^#{delimiters.collect{|d| Regexp.quote(d)}.join}]+|[#{delimiters.collect{|d| Regexp.quote(d)}.join}]")
      end
      
      def split(path)
        path.scan(url_split_regex)
      end
    end
    
    class MultiCharacterSplitterInstance
    
      def initialize(delimiters)
        @delimiters = delimiters
      end

      def split(path)
        split_path = path.split(delimiters_regexp)
        split_path.reject!{|s| s.empty? }
        split_path
      end

      protected

      def delimiters_regexp
        Regexp.new("(#{@delimiters.unescaped.collect{|d| Regexp.quote(d)}.join('|')})")
      end
      
    end    
  end
end