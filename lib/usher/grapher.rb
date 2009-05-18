require 'set'

class Usher
  class Grapher

    def initialize
      reset!
    end

    def reset!
      @significant_keys = nil
      @orders = Hash.new{|h,k| h[k] = Hash.new{|h2, k2| h2[k2] = []}}
      @key_count = Hash.new(0)
      @cache = {}
    end

    def add_route(route)
      route.paths.each do |path|
        unless path.dynamic_set.size.zero?
          path.dynamic_set.each do |k|
            @orders[path.dynamic_set.size][k] << path
            @key_count[k] += 1
          end
          
          dynamic_parts_with_defaults = path.dynamic_parts.select{|part| part.default_value }.map{|dp| dp.name}
          dynamic_parts_without_defaults = path.dynamic_parts.select{|part| !part.default_value }.map{|dp| dp.name}

          (1...(2 ** (dynamic_parts_with_defaults.size))).each do |i|
            current_set = Set.new(dynamic_parts_without_defaults)
            dynamic_parts_with_defaults.each_with_index do |dp, index|
              current_set << dp unless (index & i) == 0
            end

            current_set.each do |k|
              @orders[current_set.size][k] << path
              @key_count[k] += 1
            end
          end
        end
      end
    end

    def significant_keys
      @significant_keys ||= Set.new(@key_count.keys)
    end

    def find_matching_path(params)
      unless params.empty?
        set = Set.new(params.keys) & significant_keys
        set.size.downto(1) do |o|
          set.each do |k|
            @orders[o][k].each { |r| 
              if r.can_generate_from?(set)
                #@cache[set_a] = r
                return r
              end
            }
          end
        end
        nil
      end
    end
  end
end
