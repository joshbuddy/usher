class Usher
  class Route
    class Path
  
      attr_reader :dynamic_parts, :dynamic_map, :dynamic_indicies, :route, :parts, :dynamic_required_keys, :dynamic_keys
      
      def initialize(route, parts)
        @route = route
        @parts = parts
        @dynamic_indicies = []
        @parts.each_index{|i| @dynamic_indicies << i if @parts[i].is_a?(Variable)}
        @dynamic_parts = @parts.values_at(*@dynamic_indicies)
        @dynamic_map = {}
        @dynamic_parts.each{|p| @dynamic_map[p.name] = p }
        @dynamic_keys = @dynamic_map.keys
        @dynamic_required_keys = @dynamic_parts.select{|dp| !dp.default_value}.map{|dp| dp.name}
      end

      def can_generate_from?(keys)
        (@dynamic_required_keys - keys).size.zero?
      end
    end
  end
end