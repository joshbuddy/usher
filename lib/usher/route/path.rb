require 'usher/route/path/dynamic'

class Usher
  class Route
    class Path

      attr_accessor :cached_response, :route
      attr_reader :parts

      def self.create(route, parts)
        if parts.any?{|p| p.is_a?(Variable)}
          Path::Dynamic.new(route, parts)
        else
          Path.new(route, parts)
        end
      end

      def initialize(route, parts)
        @route = route
        @parts = parts
      end

      def convert_params_array(ary)
        ary.empty? ? ary : dynamic_keys.zip(ary)
      end

      def dynamic?
        false
      end

      def can_generate_from_keys?(keys)
        false
      end

      def can_generate_from_params?(params)
        if route.router.consider_destination_keys?
          (route.destination.to_a - params.to_a).size.zero?
        end
      end

      # Merges paths for use in generation
      def merge(other_path)
        new_parts = parts + other_path.parts
        Path.create(route, new_parts)
      end

    end
  end
end
