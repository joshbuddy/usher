require 'strscan'

class Usher
  class Splitter
    
    def self.for_delimiters(router, valid_regex)
      SplitterInstance.new(Regexp.new("[#{router.delimiters.collect{|d| Regexp.quote(d)}}]|[^#{router.delimiters.collect{|d| Regexp.quote(d)}}]+"))
    end

    class SplitterInstance
    
      def initialize(url_split_regex)
        @url_split_regex = url_split_regex
      end
      
      def url_split(path)
        path.scan(@url_split_regex)
      end
    end
    
  end
end