$:.unshift File.dirname(__FILE__)

require 'fuzzy_hash'

class Usher

  class Node
    
    ConditionalTypes = [:protocol, :domain, :port, :query_string, :remote_ip, :user_agent, :referer, :method]
    Response = Struct.new(:path, :params)
    
    attr_reader :lookup
    attr_accessor :terminates, :exclusive_type, :parent, :value

    def initialize(parent, value)
      @parent = parent
      @value = value
      @lookup = FuzzyHash.new
      @exclusive_type = nil
      @has_globber = find_parent{|p| p.value && p.value.is_a?(Route::Variable)}
    end

    def depth
      @depth ||= @parent && @parent.is_a?(Node) ? @parent.depth + 1 : 0
    end
    
    def self.root(route_set)
      self.new(route_set, nil)
    end

    def has_globber?
      @has_globber
    end

    def terminates?
      @terminates
    end

    def find_parent(&blk)
      if @parent.nil? || !@parent.is_a?(Node)
        nil
      elsif yield @parent
        @parent
      else #keep searching
        @parent.find_parent(&blk)
      end
    end

    def replace(src, dest)
      @lookup.replace(src, dest)
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
        ConditionalTypes.each do |type|
          parts.push(Route::RequestMethod.new(type, route.conditions[type])) if route.conditions[type]
        end
        
        current_node = self
        until parts.size.zero?
          key = parts.shift
          target_node = case key
          when Route::RequestMethod
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
            if current_node.exclusive_type
              parts.unshift(key)
              current_node.lookup[nil] ||= Node.new(current_node, Route::RequestMethod.new(current_node.exclusive_type, nil))
            else
              current_node.lookup[key.is_a?(Route::Variable) ? nil : key] ||= Node.new(current_node, key)
            end
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
        else
          nil
        end
      elsif next_part = @lookup[part]
        next_part.find(request, path, params)
      elsif next_part = @lookup[nil]
        if next_part.value.is_a?(Route::Variable)
          part = next_part.value.transform!(part)
          next_part.value.valid!(part)
          case next_part.value.type
          when :*
            params << [next_part.value.name, []]
            params.last.last << part
          when :':'
            params << [next_part.value.name, part]
          when:'.:'
            part.slice!(0)
            params << [next_part.value.name, part]
          end
        end
        next_part.find(request, path, params)
      elsif has_globber? && p = find_parent{|p| p.value.is_a?(Route::Variable) && p.value.type == :*}
        params.last.last << part
        find(request, path, params)
      else
        nil
      end
    end

  end
end
