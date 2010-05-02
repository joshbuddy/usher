class Usher
  # Find nearest matching routes based on parameter keys.
  class Grapher

    attr_reader :router, :orders, :key_count, :cache, :significant_keys
    
    # @param router An Usher instance you wish to create a grapher for.
    def initialize(router)
      @router = router
      reset!
    end

    # Add route for matching
    # @param route [Route] Add route for matching against
    def add_route(route)
      @cache.clear
      process_route(route)
    end

    # Finds a matching path based on params hash
    # @param params [Hash<Symbol, String>] A hash of parameters you wish to use in matching.
    # @return [nil, Route] Returns the matching {Usher::Route::Path} or nil if no path matches.
    def find_matching_path(params)
      unless params.empty?
        set = params.keys & significant_keys
        if cached = cache[set] 
          return cached
        end
        set.size.downto(1) do |o|
          set.each do |k|
            orders[o][k].each do |r| 
              if r.can_generate_from_keys?(set)
                cache[set] = r
                return r
              elsif router.consider_destination_keys? && r.can_generate_from_params?(params)
                return r
              end
            end
          end
        end
      end
      nil
    end
    
    private
    # Processes route.
    # @param route [Route] Processes the route for use in the grapher.
    def process_route(route)
      route.paths.each do |path|
        if path.dynamic?
          path.dynamic_keys.each do |k|
            orders[path.dynamic_keys.size][k] << path
            key_count[k] += 1
          end

          dynamic_parts_with_defaults    = path.dynamic_parts.select{|part| part.default_value }.map{|dp| dp.name}
          dynamic_parts_without_defaults = path.dynamic_parts.select{|part| !part.default_value }.map{|dp| dp.name}

          (1...(2 ** (dynamic_parts_with_defaults.size))).each do |i|
            current_set = dynamic_parts_without_defaults.dup
            dynamic_parts_with_defaults.each_with_index do |dp, index|
              current_set << dp unless (index & i) == 0
            end

            current_set.each do |k|
              orders[current_set.size][k] << path
              key_count[k] += 1
            end
          end

        end

        if router.consider_destination_keys?
          path.route.destination_keys.each do |k|
            orders[path.route.destination_keys.size][k] << path
            key_count[k] += 1
          end
        end
      end
      @significant_keys = key_count.keys.uniq
    end
    
    # Resets the router to its initial state.
    def reset!
      @significant_keys = nil
      @orders = Hash.new{|h,k| h[k] = Hash.new{|h2, k2| h2[k2] = []}}
      @key_count = Hash.new(0)
      @cache = {}
    end

  end
end
