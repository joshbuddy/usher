class Usher
  class Route
    class Path
      class Dynamic < Path
        
        def initialize(route, parts)
          super(route, parts)
        end

        def cached_response=(r)
          raise
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
          @dynamic_map ||= dynamic_parts.inject({}){|hash, p| hash[p.name] = p; hash }
        end

        def dynamic_keys
          @dynamic_keys ||= dynamic_parts.map{|dp| dp.name}
        end

        def dynamic_required_keys
          @dynamic_required_keys ||= dynamic_parts.select{|dp| !dp.default_value}.map{|dp| dp.name}
        end

        def dynamic?
          true
        end

        def can_generate_from_keys?(keys)
          (dynamic_required_keys - keys).size.zero? ? keys : nil
        end

        def can_generate_from_params?(params)
          if route.router.consider_destination_keys?
            (route.destination.to_a - params.to_a).size.zero?
          end
        end

      end
    end
  end
end
