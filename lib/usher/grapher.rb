class Usher
  class Grapher

    attr_reader :routes, :router, :orders, :key_count, :cache

    def initialize(router)
      @router = router
      reset!
    end

    def reset!
      @significant_keys = nil
      @orders = Hash.new{|h,k| h[k] = Hash.new{|h2, k2| h2[k2] = []}}
      @key_count = Hash.new(0)
      @cache = {}
      @routes = []
    end

    def add_route(route)#, required_keys, optional_keys)
      routes << route
    end

    def process_routes
      return if @processed 
      routes.each do |route|
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
      end
      @processed = true
    end

    def significant_keys
      @significant_keys ||= key_count.keys.uniq
    end

    def find_matching_path(params)
      unless params.empty?
        process_routes
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
    
  end
end
