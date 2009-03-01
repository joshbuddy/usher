$:.unshift File.dirname(__FILE__)

require 'node/lookup'

class Usher

  class Node
    
    ConditionalTypes = [:protocol, :domain, :port, :query_string, :remote_ip, :user_agent, :referer, :method]
    
    attr_reader :lookup, :value
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
        while (p = p.parent) && p.is_a?(Node)
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
          parts.unshift(Route::Http.new(type, route.conditions[type])) if route.conditions[type]
        end
        
        current_node = self
        until parts.size.zero?
          key = parts.shift
          target_node = case key
          when Route::Http
            if current_node.exclusive_type == key.type
              current_node.lookup[key.value] ||= Node.new(current_node, key)
            elsif current_node.exclusive_type.nil? && current_node.lookup.empty?
              current_node.exclusive_type = key.type
              current_node.lookup[key.value] ||= Node.new(current_node, key)
            elsif current_node.exclusive_type.nil? || ConditionalTypes.index(current_node.exclusive_type) < ConditionalTypes.index(key.type)
              # insert ourselves in the tree
              current_node.parent.lookup.delete_value(current_node)
              n = Node.new(current_node.parent, nil)
              current_node.parent = n
              n.exclusive_type = key.type
              n.lookup[nil] = current_node
              n
            elsif current_node.exclusive_type
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
                
        raise "terminator already taken trying to add #{path.parts * ''}" if current_node.terminates
        current_node.terminates = path
      end
      route
    end
    
    def find(request, path = Route::Splitter.split(request.path, true), params = [])
      part = path.shift unless path.size.zero?
      if @exclusive_type && (next_part = (@lookup[request.send(@exclusive_type)] || @lookup[nil]))
        path.unshift part
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
