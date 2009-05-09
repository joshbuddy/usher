$:.unshift File.dirname(__FILE__)

require '~/Development/fuzzy_hash/lib/fuzzy_hash'

class Usher

  class Node
    
    Response = Struct.new(:path, :params)
    
    attr_reader :lookup
    attr_accessor :terminates, :exclusive_type, :parent, :value, :request_methods

    def initialize(parent, value)
      @parent = parent
      @value = value
      @lookup = Hash.new
      @exclusive_type = nil
    end

    def upgrade_lookup
      @lookup = FuzzyHash.new(@lookup)
    end

    def depth
      @depth ||= @parent && @parent.is_a?(Node) ? @parent.depth + 1 : 0
    end
    
    def self.root(route_set, request_methods)
      root = self.new(route_set, nil)
      root.request_methods = request_methods
      root
    end

    def terminates?
      @terminates
    end

    def pp
      $stdout << " " * depth
      $stdout << "#{depth}: #{value.inspect} #{!!terminates?}\n"
      @lookup.each do |k,v|
        $stdout << " " * (depth + 1)
        $stdout << "#{k} ==> \n"
        v.pp
      end
    end
    
    def add(route)
      route.paths.each do |path|
        parts = path.parts.dup
        request_methods.each do |type|
          parts.push(Route::RequestMethod.new(type, route.conditions[type])) if route.conditions.key?(type)
        end
        
        current_node = self
        until parts.size.zero?
          key = parts.shift
          target_node = case key
          when Route::RequestMethod
            current_node.upgrade_lookup if key.value.is_a?(Regexp)
            if current_node.exclusive_type == key.type
              current_node.lookup[key.value] ||= Node.new(current_node, key)
            elsif current_node.lookup.empty?
              current_node.exclusive_type = key.type
              current_node.lookup[key.value] ||= Node.new(current_node, key)
            else
              parts.unshift(key)
              current_node.lookup[nil] ||= Node.new(current_node, Route::RequestMethod.new(current_node.exclusive_type, nil))
            end
          else
            current_node.upgrade_lookup if !key.is_a?(Route::Variable) && key.is_a?(Regexp)
            current_node.lookup[key.is_a?(Route::Variable) ? nil : key] ||= Node.new(current_node, key)
          end
          current_node = target_node
        end
        current_node.terminates = path
      end
      route
    end
    
    def find(request, path, params = [])
      part = path.shift unless path.size.zero?

      if @exclusive_type
        path.unshift part
        [@lookup[request.send(@exclusive_type)], @lookup[nil]].each do |n|
          ret = n.find(request, path.dup, params.dup) if n
          ret and return ret
        end
      elsif path.size.zero? && !part
        if terminates?
          Response.new(terminates, params)
        elsif params.last.is_a?(Array) && @lookup[nil]
          params.last.last.delete_if{|p| p.is_a?(Symbol)}
          if @lookup[nil].exclusive_type
            @lookup[nil].find(request, path, params)
          else
            Response.new(@lookup[nil].terminates, params)
          end
        end
      elsif next_part = @lookup[part]
        next_part.find(request, path, params)
      elsif next_part = @lookup[nil]
        if next_part.value.is_a?(Route::Variable)
          part = next_part.value.transform!(part)
          next_part.value.valid!(part)
          case next_part.value.type
          when :*
            params << [next_part.value.name, []] unless params.last && params.last.first == next_part.value.name
            if next_part.value.look_ahead === part
              path.unshift(part)
              path.unshift(params.last.last.last) if params.last.last.last.is_a?(Symbol)
              params.last.last.delete_if{|p| p.is_a?(Symbol)}
              next_part.find(request, path, params)
            else
              params.last.last << part
              find(request, path, params)
            end
          when :':'
            var = next_part.value
            params << [next_part.value.name, part]
            until (path.first == var.look_ahead) || path.empty?
              params.last.last << path.shift.to_s 
            end
            next_part.find(request, path, params)
          end
        end
      else
        nil
      end
    end

  end
end
