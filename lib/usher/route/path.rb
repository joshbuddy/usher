class Usher
  class Route
    class Path

      attr_accessor :route
      attr_reader :parts

      def initialize(route, parts)
        self.route = route
        self.parts = parts
      end

      def convert_params_array(ary)
        ary.empty? ? ary : dynamic_keys.zip(ary)
      end

      def dynamic_indicies
        unless dynamic? && @dynamic_indicies
          @dynamic_indicies = []
          parts.each_index{|i| @dynamic_indicies << i if parts[i].is_a?(Variable)}
        end
        @dynamic_indicies
      end

      def dynamic_parts
        @dynamic_parts ||= parts.values_at(*dynamic_indicies) if dynamic?
      end

      def dynamic_map
        unless dynamic? && @dynamic_map
          @dynamic_map = {}
          dynamic_parts.each{|p| @dynamic_map[p.name] = p }
        end
        @dynamic_map
      end

      def dynamic_keys
        @dynamic_keys ||= dynamic_parts.map{|dp| dp.name} if dynamic?
      end

      def dynamic_required_keys
        @dynamic_required_keys ||= dynamic_parts.select{|dp| !dp.default_value}.map{|dp| dp.name} if dynamic?
      end

      def dynamic?
        @dynamic
      end

      def can_generate_from_keys?(keys)
        if dynamic?
          (dynamic_required_keys - keys).size.zero? ? keys : nil
        end
      end

      def can_generate_from_params?(params)
        if route.router.consider_destination_keys?
          (route.destination.to_a - params.to_a).size.zero?
        end
      end

      # Merges paths for use in generation
      def merge(other_path)
        new_parts = parts + other_path.parts
        Path.new(route, new_parts)
      end

      private
      def parts=(parts)
        @parts = parts
        @dynamic = @parts && @parts.any?{|p| p.is_a?(Variable)}
      end

    end
  end
end
