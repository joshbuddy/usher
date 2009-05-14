$:.unshift File.dirname(__FILE__)

require 'fuzzy_hash'

class Usher

  class Node
    
    Response = Struct.new(:path, :params)
    
    attr_reader :lookup
    attr_accessor :terminates, :exclusive_type, :parent, :value, :request_methods, :globs_capture_separators

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
    
    def self.root(route_set, request_methods, globs_capture_separators)
      root = self.new(route_set, nil)
      root.request_methods = request_methods
      root.globs_capture_separators = globs_capture_separators
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
            key.globs_capture_separators = globs_capture_separators if key.is_a?(Route::Variable)
            
            if !key.is_a?(Route::Variable)
              current_node.upgrade_lookup if key.is_a?(Regexp)
              current_node.lookup[key] ||= Node.new(current_node, key)
            elsif key.regex_matcher
              current_node.upgrade_lookup
              current_node.lookup[key.regex_matcher] ||= Node.new(current_node, key)
            else
              current_node.lookup[nil] ||= Node.new(current_node, key)
            end  
          end
          current_node = target_node
        end
        current_node.terminates = path
      end
      route
    end
    
    def find(request, path, params = [])
      if exclusive_type
        [lookup[request.send(exclusive_type)], lookup[nil]].each do |n|
          if n && (ret = n.find(request, path.dup, params.dup))
            return ret
          end
        end
      elsif path.size.zero? && terminates?
        Response.new(terminates, params)
      elsif next_part = lookup[part = path.shift] || lookup[nil]
        case next_part.value
        when Route::Variable
          case next_part.value.type
          when :*
            params << [next_part.value.name, []] unless params.last && params.last.first == next_part.value.name
            loop do
              if (next_part.value.look_ahead === part || (!part.is_a?(Symbol) && next_part.value.regex_matcher && !next_part.value.regex_matcher.match(part)))
                path.unshift(part)
                path.unshift(next_part.parent.value) if next_part.parent.value.is_a?(Symbol)
                break
              else
                unless part.is_a?(Symbol) && !next_part.value.globs_capture_separators
                  part = next_part.value.transform!(part)
                  next_part.value.valid!(part)
                  params.last.last << part
                end
              end
              if path.size.zero?
                break
              else
                part = path.shift
              end
            end
          when :':'
            part = next_part.value.transform!(part)
            next_part.value.valid!(part)
            var = next_part.value
            params << [next_part.value.name, part]
            until (path.first == var.look_ahead) || path.empty?
              params.last.last << path.shift.to_s 
            end
          end
        end
        next_part.find(request, path, params)
      else
        nil
      end
    end

  end
end
