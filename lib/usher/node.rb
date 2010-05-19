require 'set'

require File.join('usher', 'node', 'root')
require File.join('usher', 'node', 'root_ignoring_trailing_delimiters')
require File.join('usher', 'node', 'response')
require File.join('usher', 'node', 'failed_response')

class Usher
  
  # The node class used to walk the tree looking for a matching route. The node has three different things that it looks for.
  # ## Normal
  # The normal hash is used to normally find matching parts. As well, the reserved key, `nil` is used to denote a variable match.
  # ## Greedy
  # The greedy hash is used when you want to match on the entire path. This match can trancend delimiters (unlike the normal match)
  # and match as much of the path as needed.
  # ## Request
  # The request hash is used to find request method restrictions after the entire path has been consumed.
  # 
  # Once the node finishes looking for matches, it looks for a `terminates` on the node that is usable. If it finds one, it wraps it into a {Node::Response}
  # and returns that. All actual matching though should normally be done off of {Node::Root#lookup}
  # @see Root
  class Node

    Terminates = Struct.new(:choices, :default)

    attr_reader :normal, :greedy, :request, :terminates, :unique_terminating_routes, :meta
    attr_accessor :default_terminates, :request_method_type, :parent, :value, :request_methods

    def initialize(parent, value)
      @parent, @value = parent, value
    end

    def inspect
      out = ''
      out << " " * depth
      out << "#{terminates ? '* ' : ''}#{depth}: #{value.inspect}\n"
      [:normal, :greedy, :request].each do |node_type|
        send(node_type).each do |k,v|
          out << (" " * (depth + 1)) << "#{node_type.to_s[0].chr} #{k.inspect} ==> \n" << v.inspect
        end if send(node_type)
      end
      out
    end

    def add_meta(obj)
      create_meta << obj
    end

    def add_terminate(path)
      if path.route.when_proc
        create_terminate.choices << path
      else
        create_terminate.default = path
      end
      unique_terminating_routes << path.route
    end

    def remove_terminate(path)
      if terminates
        terminates.choices.delete(path)
        terminates.default = nil if terminates.default == path
      end
      unique_terminating_routes.delete_if{|r| r == path.route}
    end

    protected

    def create_terminate
      @unique_terminating_routes ||= Set.new
      @terminates ||= Terminates.new([], nil)
    end
    
    def create_meta
      @meta ||= []
    end
    
    def depth
      @depth ||= parent.is_a?(Node) ? parent.depth + 1 : 0
    end

    def pick_terminate(request_object)
      @terminates.choices.find{|(p, t)| p.call(request_object) && t && t.route.recognizable?} || (@terminates.default && @terminates.default.route.recognizable? ? @terminates.default : nil) if @terminates
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

    def find(request_object, original_path, path, params = [], gathered_meta = nil)
      (gathered_meta ||= []).concat(meta) if meta
      # terminates or is partial
      if terminating_path = pick_terminate(request_object) and (path.empty? || terminating_path.route.partial_match?)
        response = terminating_path.route.partial_match? ?
          Response.new(terminating_path, params, path.join, original_path[0, original_path.size - path.join.size], false, gathered_meta) :
          Response.new(terminating_path, params, nil, original_path, false, gathered_meta)
      # terminates or is partial
      elsif !path.empty? and greedy and match_with_result_output = greedy.match_with_result(whole_path = path.join)
        child_node, matched_part = match_with_result_output
        whole_path.slice!(0, matched_part.size)
        params << matched_part if child_node.value.is_a?(Route::Variable)
        child_node.find(request_object, original_path, whole_path.empty? ? whole_path : route_set.splitter.split(whole_path), params, gathered_meta)
      elsif !path.empty? and normal and child_node = normal[path.first] || normal[nil]
        part = path.shift
        case child_node.value
        when String
        when Route::Variable::Single
          variable = child_node.value                               # get the variable
          variable.valid!(part)                                     # do a validity check
          until path.empty? || (variable.look_ahead === path.first) # variables have a look ahead notion,
            next_path_part = path.shift                             # and until they are satified,
            part << next_path_part
          end if variable.look_ahead
          params << part                                            # because its a variable, we need to add it to the params array
        when Route::Variable::Glob
          params << []
          loop do
            if (child_node.value.look_ahead === part || (!route_set.delimiters.unescaped.include?(part) && child_node.value.regex_matcher && !child_node.value.regex_matcher.match(part)))
              path.unshift(part)
              path.unshift(child_node.parent.value) if route_set.delimiters.unescaped.include?(child_node.parent.value)
              break
            elsif !route_set.delimiters.unescaped.include?(part)
              child_node.value.valid!(part)
              params.last << part
            end
            unless part = path.shift
              break
            end
          end
        end
        child_node.find(request_object, original_path, path, params, gathered_meta)
      elsif request_method_type
        if route_set.priority_lookups?
          route_candidates = []
          if specific_node = request[request_object.send(request_method_type)] and ret = specific_node.find(request_object, original_path, path.dup, params.dup, gathered_meta && gathered_meta.dup)
            route_candidates << ret
          end
          if general_node = request[nil] and ret = general_node.find(request_object, original_path, path.dup, params.dup, gathered_meta && gathered_meta.dup)
            route_candidates << ret
          end
          route_candidates.sort!{|r1, r2| r1.path.route.priority <=> r2.path.route.priority}
          request_method_respond(route_candidates.last, request_method_type)
        else
          if specific_node = request[request_object.send(request_method_type)] and ret = specific_node.find(request_object, original_path, path.dup, params.dup, gathered_meta && gathered_meta.dup)
            ret
          elsif general_node = request[nil] and ret = general_node.find(request_object, original_path, path.dup, params.dup, gathered_meta && gathered_meta.dup)
            request_method_respond(ret, request_method_type)
          else
            request_method_respond(nil, request_method_type)
          end
        end
      else
        route_set.detailed_failure? ? FailedResponse.new(self, :normal_or_greedy, nil) : nil
      end
    end

    def request_method_respond(ret, request_method_respond)
      ret || (route_set.detailed_failure? ? FailedResponse.new(self, :request_method, request_method_respond) : nil)
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

  end
end
