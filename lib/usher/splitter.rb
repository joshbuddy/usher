class Usher
  class Splitter

    def self.for_delimiters(delimiters_array)
      delimiters = Delimiters.new(delimiters_array)
      delimiters_array.any?{|d| d.size > 1} ?
        MultiCharacterSplitterInstance.new(delimiters) :
        SingleCharacterSplitterInstance.new(delimiters)
    end

    class SingleCharacterSplitterInstance
    
      def initialize(delimiters)
        @url_split_regex = Regexp.new("[#{delimiters.collect{|d| Regexp.quote(d)}.join}]|[^#{delimiters.collect{|d| Regexp.quote(d)}.join}]+")
      end
      
      def url_split(path)
        path.scan(@url_split_regex)
      end
      alias split url_split
    end
    
    class MultiCharacterSplitterInstance
    
      def initialize(delimiters)
        @delimiters = delimiters
      end

      def url_split(path)
        split_path = path.split(delimiters_regexp)
        split_path.reject!{|s| s.size.zero? }
        split_path
      end
      alias split url_split

      protected

      def delimiters_regexp
        Regexp.new("(#{@delimiters.unescaped.collect{|d| Regexp.quote(d)}.join('|')})")
      end
      
    end    
  end
end