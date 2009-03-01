class Usher
  class Node
    class Lookup
      
      def initialize
        @hash = {}
        @regexes = []
        @hash_reverse = {}
        @regexes_reverse = {}
      end
      
      def keys
        @hash.keys + @regexes.collect{|r| r.first}
      end
      
      def values
        @hash.values + @regexes.collect{|r| r.last}
      end
      
      def []=(key, value)
        case key
        when Regexp
          @regexes << [key, value]
          @regex_test = nil
          @regexes_reverse[value] = [@regexes.size - 1, key, value]
        else
          @hash[key] = value
          @hash_reverse[value] = key
        end
      end
      
      def replace(src, dest)
        if @hash_reverse.key?(src)
          key = @hash_reverse[src]
          @hash[key] = dest
          @hash_reverse.delete(src)
          @hash_reverse[dest] = key
        elsif @regexes_reverse.key?(src)
          key = @regexes_reverse[src]
          @regexes[rkey[0]] = [rkey[1], dest]
          @regexes_reverse.delete(src)
          @regexes_reverse[dest] = [rkey[0], rkey[1], dest]
        end
      end
      
      def [](key)
        @hash[key] || regex_lookup(key)
      end
      
      private
      def regex_test
        @regex_test ||= Regexp.union(*@regexes.collect{|r| r[0]})
      end
      
      def regex_lookup(key)
        if key.is_a?(String)
          if data = regex_test.match(key)
            (data_array = data.to_a).each_index do |i|
              break @regexes[i].last if data_array.at(i)
            end
          end
        end
      end
      
    end
  end
end