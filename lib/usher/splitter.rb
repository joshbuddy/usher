class Usher
  class Splitter

    def self.new(delimiters_array)
      delimiters = Delimiters.new(delimiters_array)
      delimiters.any?{|d| d.size > 1} ?
        MultiCharacterSplitterInstance.new(delimiters) :
        SingleCharacterSplitterInstance.new(delimiters)
    end

    class SingleCharacterSplitterInstance
    
      def initialize(delimiters)
        @url_split_regex = Regexp.new("[^#{delimiters.regexp_char_class}]+|[#{delimiters.regexp_char_class}]")
      end
        
      def split(path)
        path.scan(@url_split_regex)
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
        @delimiters.regexp
      end
      
    end    
  end
end