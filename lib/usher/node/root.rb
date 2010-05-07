class Usher
  class Node
    class Root < Node

      def initialize(route_set, request_methods)
        super(route_set, nil)
        self.request_methods = request_methods
      end
      
      def route_set
        parent
      end
      
      def add(route)
        get_nodes_for_route(route) {|p, n| n.add_terminate(p)}
      end

      def delete(route)
        get_nodes_for_route(route) {|p, n| n.remove_terminate(p)}
      end

      def add_meta(route, obj)
        get_nodes_for_route(route) {|p, n| n.add_meta(obj)}
      end

      def unique_routes(node = self, routes = [])
        routes.concat(node.unique_terminating_routes.to_a) if node.unique_terminating_routes
        [:normal, :greedy, :request].each { |type| node.send(type).values.each { |v| unique_routes(v, routes) } if node.send(type) }
        routes.uniq!
        routes
      end

      def lookup(request_object, path)
        find(request_object, path, route_set.splitter.split(path))
      end
      
      private
      
      def set_path_with_destination(path, destination = path)
        get_nodes(path) {|n| n.add_terminate(destination)}
      end

      def get_nodes_for_route(route)
        route.paths.each do |path|
          nodes = [path.parts ? path.parts.inject(self){ |node, key| process_path_part(node, key)} : self]
          nodes = process_request_parts(nodes, request_methods_for_path(path)) if request_methods
          nodes.each do |node|
            while node.request_method_type
              node = (node.request[nil] ||= Node.new(node, Route::RequestMethod.new(node.request_method_type, nil)))
            end
            yield path, node
          end
        end
      end
      
      def request_method_index(type)
        request_methods.index(type)
      end

      def process_request_parts(nodes, parts)
        while parts.any?{ |p| !p.trivial? }
          key = parts.shift

          next if key.trivial?
          nodes.map! do |node|
            node.activate_request!
            if node.request_method_type.nil?
              node.request_method_type = key.type
              node.upgrade_request! if key.value.is_a?(Regexp)
              Array(key.value).map{|k| node.request[k] ||= Node.new(node, key) }
            else
              case request_method_index(node.request_method_type) <=> request_method_index(key.type)
              when -1
                parts.unshift(key)
                Array(key.value).map{|k| node.request[nil] ||= Node.new(node, Route::RequestMethod.new(node.request_method_type, nil)) }
              when 0
                node.upgrade_request! if key.value.is_a?(Regexp)
                Array(key.value).map{|k| node.request[k] ||= Node.new(node, key) }
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
          nodes.flatten!
        end
        nodes
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
        when Route::Static::Greedy
          node.activate_greedy!
          node.upgrade_greedy!
          node.greedy[key] ||= Node.new(node, key)
        else
          node.activate_normal!
          node.upgrade_normal! if key.is_a?(Regexp)
          node.normal[key] ||= Node.new(node, key)
        end
      end

      def request_methods_for_path(path)
        request_methods.collect { |type| Route::RequestMethod.new(type, path.route.conditions && path.route.conditions[type]) }
      end
      
    end
  end
end

