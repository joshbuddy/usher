class Usher
  class Node
    class Response < Struct.new(:path, :params_as_array, :remaining_path, :matched_path)

      def params
        @params ||= path.convert_params_array(params_as_array)
      end

      def partial_match?
        !remaining_path.nil?
      end

      def params_as_hash
        @params_as_hash ||= params_as_array.inject({}){|hash, val| hash[path.dynamic_keys[hash.size]] = val; hash}
      end

      def destination
        path && path.route.destination
      end
    end
  end
end