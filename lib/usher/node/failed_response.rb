class Usher
  class Node
    # The response from {Usher::Node::Root#lookup}. Adds some convenience methods for common parameter manipulation.
    class FailedResponse < Struct.new(:last_matching_node, :fail_type, :fail_sub_type)
      # The success of the response
      # @return [Boolean] Always returns false
      def succeeded?
        false
      end
      
      def request_method?
        fail_type == :request_method
      end

      def normal_or_greedy?
        fail_type == :normal_or_greedy
      end
      
      def acceptable_responses
        case fail_type
        when :request_method
          last_matching_node.request.keys
        when :normal_or_greedy
          (last_matching_node.greedy || []) + (last_matching_node.normal || [])
        end
      end

      def acceptable_responses_only_strings
        acceptable_responses.select{|r| r.is_a?(String)}
      end

    end
  end
end
