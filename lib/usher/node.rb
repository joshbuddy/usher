$:.unshift File.dirname(__FILE__)

require 'node/lookup'

class Usher

  class Node
    
    ConditionalTypes = [:protocol, :domain, :port, :query_string, :remote_ip, :user_agent, :referer, :method]
    
    attr_reader :value, :lookup
    attr_accessor :terminates, :exclusive_type, :parent

    def initialize(parent, value)
      @parent = parent
      @value = value
      @lookup = Lookup.new
      @exclusive_type = nil
      @has_globber = find_parent{|p| p.value && p.value.is_a?(Route::Variable)}
    end

    def depth
      unless @depth
        @depth = 0
        p = self
        while not (p = p.parent).nil?
          @depth += 1
        end
      end
      @depth
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

    def add(route)
      route.paths.each do |path|
        parts = path.parts.dup
        ConditionalTypes.each do |type|
          parts << Route::Http.new(type, route.conditions[type]) if route.conditions[type]
        end
        
        current_node = self
        until parts.size.zero?
          key = parts.shift
          target_node = case key
          when Route::Http
            if current_node.exclusive_type == key.type
              # same type, keep using it
              current_node.lookup[key.value] ||= Node.new(current_node, key)
            elsif current_node.exclusive_type.nil? || ConditionalTypes.index(current_node.exclusive_type) < ConditionalTypes.index(key.type)
              # insert yourself into the chain
              n = Node.new(current_node.parent, key)
              
              current_node.parent = n
              n.exclusive_type = key.type
              n.parent.replace(current_node, n)
              parts.unshift(key)
              n
            else
              # you're exclusive too, but you have to go later. sorry.
              parts.unshift(key)
              current_node.lookup[nil] ||= Node.new(current_node, Route::Http.new(current_node.exclusive_type, nil))
            end
          else
            if current_node.exclusive_type
              parts.unshift(key)
              current_node.lookup[nil] ||= Node.new(current_node, Route::Http.new(current_node.exclusive_type, nil))
            else
              current_node.lookup[key.is_a?(Route::Variable) ? nil : key] ||= Node.new(current_node, key)
            end
          end
          current_node = target_node
        end
        raise "terminator already taken" if current_node.terminates
        current_node.terminates = path
        
      end
      route
    end
    
    def find(request, path = Route::Splitter.split(request.path, true), params = [])
      part = path.shift unless path.size.zero?
      if @exclusive_type && next_part = (@lookup[request.send(@exclusive_type)] || @lookup[nil])
        path.unshift(part)
        next_part.find(request, path, params)
      elsif path.size.zero? && !part
        if terminates?
          [terminates, params]
        else
          raise UnrecognizedException.new
        end
      elsif next_part = @lookup[part]
        next_part.find(request, path, params)
      elsif next_part = @lookup[nil]
        if next_part.value.is_a?(Route::Variable)
          raise "#{part} does not conform to #{next_part.value.validator}" if next_part.value.validator && (not next_part.value.validator === part)
          case next_part.value.type
          when :*
            params << [next_part.value.name, []]
            params.last.last << part unless next_part.is_a?(Route::Separator)
          when :':'
            params << [next_part.value.name, part]
          end
        end
        next_part.find(request, path, params)
      elsif has_globber? && p = find_parent{|p| !p.is_a?(Route::Separator)} && p.value.is_a?(Route::Variable) && p.value.type == :*
        params.last.last << part unless part.is_a?(Route::Separator)
        find(request, path, params)
      else
        raise UnrecognizedException.new("did not recognize #{part} in possible values #{@lookup.keys.inspect}")
      end
    end

  end
end
