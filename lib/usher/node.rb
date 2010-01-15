require File.join('usher', 'node', 'root')
require File.join('usher', 'node', 'response')

class Usher
  class Node

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
      @greedy
    end

    def terminates?
      @terminates && @terminates.route.recognizable?
    end

    def ancestors
      unless @ancestors
        @ancestors = []
        node = self
        while (node.respond_to?(:parent))
          @ancestors << node
          node = node.parent
        end
      end
      @ancestors
    end

    def root
      @root ||= ancestors.last
    end
    
    def route_set
      @route_set ||= root.route_set
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

    def single_variable(part, next_part, params, path, position)
      # get the variable
      variable = next_part.value
      # do a validity check
      variable.valid!(part)
      # because its a variable, we need to add it to the params array
      parameter_value = part
      if variable.look_ahead
        until path.empty? || (variable.look_ahead === path.first)           # variables have a look ahead notion,
          next_path_part = path.shift                                       # and until they are satified,
          position += next_path_part.size                                   # keep appending to the value in params
          parameter_value << next_path_part
        end
      end
      params << parameter_value
      position
    end

    def glob_variable(part, next_part, params, path, position)
      params << []
      loop do
        if (next_part.value.look_ahead === part || (!route_set.delimiters.unescaped.include?(part) && next_part.value.regex_matcher && !next_part.value.regex_matcher.match(part)))
          path.unshift(part)
          position -= part.size
          if route_set.delimiters.unescaped.include?(next_part.parent.value)
            path.unshift(next_part.parent.value)
            position -= next_part.parent.value.size
          end
          break
        elsif !route_set.delimiters.unescaped.include?(part)
          next_part.value.valid!(part)
          params.last << part
        end
        if path.empty?
          break
        else
          part = path.shift
        end
      end
      position
    end
    
    def find(request_object, original_path, path, params = [], position = 0)
      # terminates or is partial
      if terminates? && (path.empty? || terminates.route.partial_match? || (route_set.ignore_trailing_delimiters? && path.all?{|p| route_set.delimiters.include?(p)}))
        if terminates.cached_response
          terminates.cached_response
        else
          terminates.route.partial_match? ?
            Response.new(terminates, params, original_path[position, original_path.size], original_path[0, position]) :
            Response.new(terminates, params, nil, original_path)
        end
      # terminates or is partial
      elsif !path.empty? and greedy and match_with_result_output = greedy.match_with_result(whole_path = original_path[position, original_path.size])
        next_path, matched_part = match_with_result_output
        position += matched_part.size
        whole_path.slice!(0, matched_part.size)
        params << matched_part if next_path.value.is_a?(Route::Variable)
        next_path.find(request_object, original_path, whole_path.empty? ? whole_path : route_set.splitter.split(whole_path), params, position)
      elsif !path.empty? and normal and next_part = normal[path.first] || normal[nil]
        part = path.shift
        position += part.size
        case next_part.value
        when String
        when Route::Variable::Single
          position = single_variable(part, next_part, params, path, position)
        when Route::Variable::Glob
          position = glob_variable(part, next_part, params, path, position)
        end
        next_part.find(request_object, original_path, path, params, position)
      elsif request_method_type
        return_value = if (specific_node = request[request_object.send(request_method_type)] and ret = specific_node.find(request_object, original_path, path.dup, params && params.dup, position))
          route_set.priority_lookups? ? [ret] : ret
        end

        if route_set.priority_lookups? || return_value.nil? and general_node = request[nil] and ret = general_node.find(request_object, original_path, path.dup, params && params.dup, position)
          return_value = route_set.priority_lookups? && return_value ? [return_value, ret] : ret
        end

        unless route_set.priority_lookups?
          return_value
        else
          return_value = Array(return_value).flatten.compact
          return_value.sort!{|r1, r2| r1.path.route.priority <=> r2.path.route.priority}
          return_value.last
        end
      else
        nil
      end
    end

  end
end
