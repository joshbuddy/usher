class Usher
  class Node
    class RootIgnoringTrailingDelimiters < Root

      alias_method :lookup_without_stripping, :lookup
    
      def initialize(route_set, request_methods)
        super
        @stripper = /#{Regexp.quote(route_set.delimiters.first)}$/
      end
    
      def lookup(request_object, path)
        if path.size > 1
          new_path = path.gsub(@stripper, '')
          response = lookup_without_stripping(request_object, new_path)
          response.only_trailing_delimiters = (new_path.size != path.size) if response && response.succeeded?
          response
        else
          lookup_without_stripping(request_object, path)
        end
      end
    end
  end
end