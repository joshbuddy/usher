require 'fuzzy_hash'

class Usher

  class Node
    
    Response = Struct.new(:path, :params, :remaining_path, :matched_path)
    
    attr_reader :normal, :greedy, :request
    attr_accessor :terminates, :request_method_type, :parent, :value, :request_methods

    def initialize(parent, value)
      @parent = parent
      @value = value
      @request = nil
      @normal = nil
      @greedy = nil
      @request_method_type = nil
    end
    
    def activate_normal!
      @normal ||= Hash.new
    end

    def activate_greedy!
      @greedy ||= Hash.new
    end

    def activate_request!
      @request ||= Hash.new
    end

    def upgrade_normal!
      @normal = FuzzyHash.new(@normal)
    end

    def upgrade_greedy!
      @greedy = FuzzyHash.new(@greedy)
    end

    def upgrade_request!
      @request = FuzzyHash.new(@request)
    end

    def depth
      @depth ||= @parent.is_a?(Node) ? @parent.depth + 1 : 0
    end
    
    def greedy?
      @greedy && !@greedy.empty?
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
      $stdout << "#{terminates? ? '* ' : ''}#{depth}: #{value.inspect}\n"
      normal.each do |k,v|
        $stdout << " " * (depth + 1)
        $stdout << ". #{k.inspect} ==> \n"
        v.pp
      end if normal
      greedy.each do |k,v|
        $stdout << " " * (depth + 1)
        $stdout << "g #{k.inspect} ==> \n"
        v.pp
      end if greedy
      request.each do |k,v|
        $stdout << " " * (depth + 1)
        $stdout << "r #{k.inspect} ==> \n"
        v.pp
      end if request
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
      node.normal.values.each do |v|
        unique_routes(v, routes)
      end if node.normal
      node.greedy.values.each do |v|
        unique_routes(v, routes)
      end if node.greedy
      node.request.values.each do |v|
        unique_routes(v, routes)
      end if node.request
      routes.uniq!
      routes
    end
    
    def find(usher, request_object, original_path, path, params = [], position = 0)
      if terminates? && (path.empty? || terminates.route.partial_match?)
        terminates.route.partial_match? ?
          Response.new(terminates, params, original_path[position, original_path.size], original_path[0, position]) :
          Response.new(terminates, params, nil, original_path)
      elsif !path.empty? && (greedy? && (match_with_result_output = greedy.match_with_result(whole_path = original_path[position, original_path.size])))
				next_path, matched_part = match_with_result_output
        position += matched_part.size
        params << [next_path.value.name, whole_path.slice!(0, matched_part.size)]
        next_path.find(usher, request_object, original_path, whole_path.empty? ? whole_path : usher.splitter.url_split(whole_path), params, position)
      elsif !path.empty? && normal && (next_part = normal[part = path.shift] || normal[nil])
        position += part.size
        case next_part.value
        when Route::Variable::Glob
          params << [next_part.value.name, []] unless params.last && params.last.first == next_part.value.name
          while true
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
            if path.empty?
              break
            else
              part = path.shift
            end
          end
        when Route::Variable::Single
          var = next_part.value
          var.valid!(part)
          params << [var.name, part]
          until path.empty? || (var.look_ahead === path.first)
            next_path_part = path.shift
            position += next_path_part.size
            params.last.last << next_path_part
          end if var.look_ahead && usher.delimiter_chars.size > 1
        end
        next_part.find(usher, request_object, original_path, path, params, position)
      elsif request_method_type
        if (specific_node = request[request_object.send(request_method_type)]) && (ret = specific_node.find(usher, request_object, original_path, path.dup, params.dup, position))
          ret
        elsif (general_node = request[nil]) && (ret = general_node.find(usher, request_object, original_path, path.dup, params.dup, position))
          ret
        else
          nil
        end
      else
        nil
      end
    end

    private
    
    def set_path_with_destination(path, destination = path)
      node = path.parts.inject(self){ |node, key| process_path_part(node, key) }
      node = process_request_parts(node, request_methods_for_path(path))

      while node.request_method_type
        node = (node.request[nil] ||= Node.new(node, Route::RequestMethod.new(node.request_method_type, nil)))
      end

      node.terminates = destination
    end
    
    def request_method_index(type)
      request_methods.index(type)
    end
    
    def process_request_parts(node, parts)
      while parts.any?{ |p| !p.trivial? }
        key = parts.shift

        next if key.trivial?

        node.activate_request!

        node = if node.request_method_type.nil?
          node.request_method_type = key.type
          node.upgrade_request! if key.value.is_a?(Regexp)
          node.request[key.value] ||= Node.new(node, key)
        else
          case request_method_index(node.request_method_type) <=> request_method_index(key.type)
          when -1
            parts.unshift(key)
            node.request[key.value] ||= Node.new(node, Route::RequestMethod.new(node.request_method_type, nil))
          when 0
            node.upgrade_request! if key.value.is_a?(Regexp)
            node.request[key.value] ||= Node.new(node, key)
          when 1
            previous_node = node.parent
            current_node_entry_key = nil
            current_node_entry_lookup = nil
            [previous_node.normal, previous_node.greedy, previous_node.request].compact.each do |l|
              current_node_entry_key = l.each{|k,v| break k if node == v}
              current_node_entry_lookup = l and break if current_node_entry_key
            end

            current_node_entry_lookup.respond_to?(:delete_value) ? 
              current_node_entry_lookup.delete_value(node) : current_node_entry_lookup.delete_if{|k,v| v == node}

            new_node = Node.new(previous_node, Route::RequestMethod.new(key.type, nil))
            new_node.activate_request!
            new_node.request_method_type = key.type
            current_node_entry_lookup[current_node_entry_key] = new_node
            node.parent = new_node
            new_node.request[nil] = node
            parts.unshift(key)

            new_node
          end
        end
      end
      node
    end      
      
    
    def process_path_part(node, key)
      case key
      when Route::Variable::Greedy
        node.activate_greedy!
        if key.regex_matcher
          node.upgrade_greedy!
          node.greedy[key.regex_matcher] ||= Node.new(node, key)
        else
          node.greedy[nil] ||= Node.new(node, key)
        end  
      when Route::Variable
        node.activate_normal!
        if key.regex_matcher
          node.upgrade_normal!
          node.normal[key.regex_matcher] ||= Node.new(node, key)
        else
          node.normal[nil] ||= Node.new(node, key)
        end
      else
        node.activate_normal!
        node.upgrade_normal! if key.is_a?(Regexp)
        node.normal[key] ||= Node.new(node, key)
      end
    end
    
    def request_methods_for_path(path)
      request_methods.collect do |type|
        Route::RequestMethod.new(type, path.route.conditions && path.route.conditions[type])
      end
    end
    
  end
end
