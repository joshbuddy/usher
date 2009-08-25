require 'fuzzy_hash'

class Usher

  class Node
    
    Response = Struct.new(:path, :params, :remaining_path, :matched_path)
    
    attr_reader :lookup, :greedy_lookup
    attr_accessor :terminates, :exclusive_type, :parent, :value, :request_methods

    def initialize(parent, value)
      @parent = parent
      @value = value
      @lookup = Hash.new
      @greedy_lookup = Hash.new
      @exclusive_type = nil
    end

    def upgrade_lookup
      @lookup = FuzzyHash.new(@lookup)
    end

    def upgrade_greedy_lookup
      @greedy_lookup = FuzzyHash.new(@greedy_lookup)
    end

    def depth
      @depth ||= @parent.is_a?(Node) ? @parent.depth + 1 : 0
    end
    
    def greedy?
      !@greedy_lookup.empty?
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
        set_path_with_destination(path)
      end
    end
    
    def delete(route)
      route.paths.each do |path|
        set_path_with_destination(path, nil)
      end
    end
    
    def unique_routes(node = self, routes = [])
      routes << node.terminates.route if node.terminates
      node.lookup.values.each do |v|
        unique_routes(v, routes)
      end
      node.greedy_lookup.values.each do |v|
        unique_routes(v, routes)
      end
      routes.uniq!
      routes
    end
    
    def find(usher, request, original_path, path, params = [], position = 0)
      if exclusive_type
        [lookup[request.send(exclusive_type)], lookup[nil]].each do |n|
          if n && (ret = n.find(usher, request, original_path, path.dup, params.dup, position))
            return ret
          end
        end
      elsif terminates? && (path.size.zero? || terminates.route.partial_match?)
        if terminates.route.partial_match?
          Response.new(terminates, params, original_path[position, original_path.size], original_path[0, position])
        else
          Response.new(terminates, params, nil, original_path)
        end
        
      elsif !path.size.zero? && (greedy? && (match_with_result_output = greedy_lookup.match_with_result(whole_path = original_path[position, original_path.size])))
				next_path, matched_part = match_with_result_output
        position += matched_part.size
        params << [next_path.value.name, whole_path.slice!(0, matched_part.size)]
        next_path.find(usher, request, original_path, whole_path.size.zero? ? whole_path : usher.splitter.url_split(whole_path), params, position)
      elsif !path.size.zero? && (next_part = lookup[part = path.shift] || lookup[nil])
        position += part.size
        case next_part.value
        when Route::Variable::Glob
          params << [next_part.value.name, []] unless params.last && params.last.first == next_part.value.name
          loop do
            if (next_part.value.look_ahead === part || (!usher.delimiter_chars.include?(part[0]) && next_part.value.regex_matcher && !next_part.value.regex_matcher.match(part)))
              path.unshift(part)
              position -= part.size
              if usher.delimiter_chars.include?(next_part.parent.value[0])
                path.unshift(next_part.parent.value)
                position -= next_part.parent.value.size
              end
              break
            elsif !usher.delimiter_chars.include?(part[0])
              next_part.value.valid!(part)
              params.last.last << part
            end
            if path.size.zero?
              break
            else
              part = path.shift
            end
          end
        when Route::Variable::Single
          var = next_part.value
          var.valid!(part)
          params << [var.name, part]
          until (var.look_ahead === path.first) || path.empty?
            next_path_part = path.shift
            position += next_path_part.size
            params.last.last << next_path_part
          end
        end
        next_part.find(usher, request, original_path, path, params, position)
      else
        nil
      end
    end

    private
    def set_path_with_destination(path, destination = path)
      parts = path.parts.dup
      request_methods.each do |type|
        parts.push(Route::RequestMethod.new(type, path.route.conditions[type])) if path.route.conditions && path.route.conditions.key?(type)
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
        when Route::Variable
          upgrade_method, lookup_method = case key
          when Route::Variable::Greedy
            [:upgrade_greedy_lookup, :greedy_lookup]
          else
            [:upgrade_lookup, :lookup]
          end
          
          if key.regex_matcher
            current_node.send(upgrade_method)
            current_node.send(lookup_method)[key.regex_matcher] ||= Node.new(current_node, key)
          else
            current_node.send(lookup_method)[nil] ||= Node.new(current_node, key)
          end  
        else
          current_node.upgrade_lookup if key.is_a?(Regexp)
          current_node.lookup[key] ||= Node.new(current_node, key)
        end
        current_node = target_node
      end
      current_node.terminates = destination
    end
    
    
  end
end
