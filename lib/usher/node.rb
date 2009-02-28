class Usher

  class Node
    attr_reader :value, :parent, :lookup, :urgent_lookup
    attr_accessor :terminates, :urgent_lookup_type

    def initialize(parent, value)
      @parent = parent
      @value = value
      @lookup = {}
      @urgent_lookup_type = nil
      @urgent_lookup = {}
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
    
    def self.root
      self.new(nil, nil)
    end

    def has_globber?
      @has_globber
    end

    def terminates?
      @terminates
    end

    def find_parent(&blk)
      if @parent.nil?
        nil
      elsif yield @parent
        @parent
      else #keep searching
        @parent.find_parent(&blk)
      end
    end

    def add(route)
      method = route.conditions.delete(:method)
      route.paths.each do |path|
        parts = route.conditions.keys.collect{|k| Route::Urgent.new(k, route.conditions[k])} + path.parts.dup
        parts << Route::Urgent.new(:method, method) if method
        current_node = self
        until parts.size.zero?
          key = parts.shift
          target_node = case key
          when Route::Urgent
            if current_node.lookup.empty? && (current_node.urgent_lookup_type.nil? || current_node.urgent_lookup_type == key.type)
              n = current_node.urgent_lookup[key.value] ||= Node.new(current_node, key)
              current_node.urgent_lookup_type = key.type
            else
              parts.unshift(key)
            end
            n
          else
            current_node.lookup[key.is_a?(Route::Variable) ? nil : key] ||= Node.new(current_node, key)
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
      if @urgent_lookup_type && next_part = @urgent_lookup[request.send(@urgent_lookup_type)]
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
