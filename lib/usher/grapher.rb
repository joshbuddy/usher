require 'singleton'

class Usher
  class Grapher
    include Singleton

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
            @orders[o][k].each { |r| return r if r.dynamic_set.subset?(set) }
          end
        end
        nil
      end
    end
  end
end
