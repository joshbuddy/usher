class Usher
  class Splitter

    def self.for_delimiters(delimiters)      
      SplitterInstance.new(delimiters)
    end

    class SplitterInstance
    
      def initialize(delimiters)
        @delimiters = delimiters
      end

      def url_split(path)
        scanner = StringScanner.new(path)
        result = []
        while ! scanner.eos?
          result << scanner.scan(delimiters_regexp)
          part = scanner.scan_before(delimiters_regexp)
          result << part unless part.empty?
        end
        result.compact
      end

      alias split url_split

    protected

      def delimiters_regexp
        if @delimiters_regexp.nil?
          # TODO: extract a class (Usher::Delimiters ?) which will handle all the operations with delimiters, including regexp generation
          tokens = @delimiters.collect{|d| Regexp.quote(d)} + ['$']
          @delimiters_regexp = Regexp.new(tokens * '|')
        end
        
        @delimiters_regexp
      end

    end    
  end
end