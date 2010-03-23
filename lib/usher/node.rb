require File.join('usher', 'node', 'root')
require File.join('usher', 'node', 'response')

class Usher
  class Node

    attr_reader :normal, :greedy, :request
    attr_accessor :terminates, :request_method_type, :parent, :value, :request_methods

    def initialize(parent, value)
      @parent, @value = parent, value
    end

    def activate_normal!
      @normal ||= {}
    end

    def activate_greedy!
      @greedy ||= {}
    end

    def activate_request!
      @request ||= {}
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
      @depth ||= parent.is_a?(Node) ? parent.depth + 1 : 0
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

    def inspect
      out = ''
      out << " " * depth
      out << "#{terminates? ? '* ' : ''}#{depth}: #{value.inspect}\n"
      normal.each do |k,v|
        out << " " * (depth + 1)
        out << ". #{k.inspect} ==> \n"
        out << v.inspect
      end if normal
      greedy.each do |k,v|
        out << " " * (depth + 1)
        out << "g #{k.inspect} ==> \n"
        out << v.inspect
      end if greedy
      request.each do |k,v|
        out << " " * (depth + 1)
        out << "r #{k.inspect} ==> \n"
        out << v.inspect
      end if request
      out
    end

    def find(request_object, original_path, path, params = [])
      # terminates or is partial
      if terminates? && (path.nil? || path.empty? || terminates.route.partial_match? || (route_set.ignore_trailing_delimiters? and only_trailing_delimiters = path.all?{|p| route_set.delimiters.include?(p)}))
        terminates.route.partial_match? ?
          Response.new(terminates, params, path.join, original_path[0, original_path.size - path.join.size], only_trailing_delimiters) :
          Response.new(terminates, params, nil, original_path, only_trailing_delimiters)
      # terminates or is partial
      elsif greedy && !path.empty? and match_with_result_output = greedy.match_with_result(whole_path = path.join)
        next_path, matched_part = match_with_result_output
        whole_path.slice!(0, matched_part.size)
        params << matched_part if next_path.value.is_a?(Route::Variable)
        next_path.find(request_object, original_path, whole_path.empty? ? whole_path : route_set.splitter.split(whole_path), params)
      elsif normal && !path.empty? and next_part = normal[path.first] || normal[nil]
        part = path.shift
        case next_part.value
        when String
        when Route::Variable::Single
          variable = next_part.value                                  # get the variable
          variable.valid!(part)                                       # do a validity check
          until (variable.look_ahead === path.first) || path.empty? # variables have a look ahead notion,
            next_path_part = path.shift                             # and until they are satified,
            part << next_path_part
          end if variable.look_ahead
          params << part                                              # because its a variable, we need to add it to the params array
        when Route::Variable::Glob
          params << []
          loop do
            if (next_part.value.look_ahead === part || (!route_set.delimiters.unescaped.include?(part) && next_part.value.regex_matcher && !next_part.value.regex_matcher.match(part)))
              path.unshift(part)
              path.unshift(next_part.parent.value) if route_set.delimiters.unescaped.include?(next_part.parent.value)
              break
            elsif !route_set.delimiters.unescaped.include?(part)
              next_part.value.valid!(part)
              params.last << part
            end
            unless part = path.shift
              break
            end
          end
        end
        next_part.find(request_object, original_path, path, params)
      elsif request_method_type
        if route_set.priority_lookups?
          route_candidates = []
          if specific_node = request[request_object.send(request_method_type)] and ret = specific_node.find(request_object, original_path, path.dup, params && params.dup)
            route_candidates << ret
          end
          if general_node = request[nil] and ret = general_node.find(request_object, original_path, path.dup, params && params.dup)
            route_candidates << ret
          end
          route_candidates.sort!{|r1, r2| r1.path.route.priority <=> r2.path.route.priority}
          route_candidates.last
        else
          if specific_node = request[request_object.send(request_method_type)] and ret = specific_node.find(request_object, original_path, path.dup, params && params.dup)
            ret
          elsif general_node = request[nil] and ret = general_node.find(request_object, original_path, path.dup, params && params.dup)
            ret
          end
        end
      else
        nil
      end
    end

  end
end
