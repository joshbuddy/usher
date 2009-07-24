class Usher
  class Route
    class Path
  
      attr_reader :route, :parts
      
      def initialize(route, parts)
        @route = route
        @parts = parts
        @dynamic = @parts.any?{|p| p.is_a?(Variable)}
      end

      def dynamic_indicies
        unless @dynamic_indicies
          @dynamic_indicies = []
          parts.each_index{|i| @dynamic_indicies << i if parts[i].is_a?(Variable)}
        end
        @dynamic_indicies
      end

      def dynamic_parts
        @dynamic_parts ||= parts.values_at(*dynamic_indicies)
      end

      def dynamic_map
        unless @dynamic_map
          @dynamic_map = {}
          dynamic_parts.each{|p| @dynamic_map[p.name] = p }
        end
        @dynamic_map
      end
      
      def dynamic_keys
        @dynamic_keys ||= dynamic_map.keys
      end
      
      def dynamic_required_keys
        @dynamic_required_keys ||= dynamic_parts.select{|dp| !dp.default_value}.map{|dp| dp.name}
      end
      
      
      def dynamic?
        @dynamic
      end

      def can_generate_from?(keys)
        (dynamic_required_keys - keys).size.zero?
      end
    end
  end
end