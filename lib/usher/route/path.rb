require 'set'

class Usher
  class Route
    class Path
  
      attr_reader :dynamic_parts, :dynamic_map, :dynamic_indicies, :route, :dynamic_set, :parts
      
      def initialize(route, parts)
        @route = route
        @parts = parts
        @dynamic_indicies = []
        @parts.each_index{|i| @dynamic_indicies << i if @parts[i].is_a?(Variable)}
        @dynamic_parts = @parts.values_at(*@dynamic_indicies)
        @dynamic_map = {}
        @dynamic_parts.each{|p| @dynamic_map[p.name] = p }
        @dynamic_set = Set.new(@dynamic_map.keys)
      end
  
    end
  end
end