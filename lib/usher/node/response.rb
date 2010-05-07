class Usher
  class Node
    # The response from {Usher::Node::Root#lookup}. Adds some convenience methods for common parameter manipulation.
    class Response < Struct.new(:path, :params_as_array, :remaining_path, :matched_path, :only_trailing_delimiters, :meta)
      
      # The success of the response
      # @return [Boolean] Always returns true
      def succeeded?
        true
      end

      # The params from recognition
      # @return [Array<Symbol, String>] The parameters detected from recognition returned as an array of arrays.
      def params
        @params ||= path.convert_params_array(params_as_array)
      end

      # @return [Boolean] The state of partial matching
      def partial_match?
        !remaining_path.nil?
      end

      # The params from recognition
      # @return [Hash<Symbol, String>] The parameters detected from recognition returned as a hash.
      def params_as_hash
        @params_as_hash ||= params_as_array.inject({}){|hash, val| hash[path.dynamic_keys[hash.size]] = val; hash}
      end

      # @return [Object] The destination assigned to the matching enclosed path.
      def destination
        path && path.route.destination
      end
    end
  end
end