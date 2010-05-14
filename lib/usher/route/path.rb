class Usher
  class Route
    class Path

      attr_accessor :route
      attr_reader :parts

      def initialize(route, parts)
        self.route = route
        self.parts = parts
        build_generator
      end

      def ==(other_path)
        other_path.is_a?(Path) ? route == other_path.route && parts == other_path.parts : nil
      end
      
      def convert_params_array(ary)
        ary.empty? ? ary : dynamic_keys.zip(ary)
      end

      def dynamic_indicies
        unless dynamic? && @dynamic_indicies
          @dynamic_indicies = []
          parts.each_index{|i| @dynamic_indicies << i if parts[i].is_a?(Variable)}
        end
        @dynamic_indicies
      end

      def dynamic_parts
        @dynamic_parts ||= parts.values_at(*dynamic_indicies) if dynamic?
      end

      def dynamic_map
        unless dynamic? && @dynamic_map
          @dynamic_map = {}
          dynamic_parts.each{|p| @dynamic_map[p.name] = p }
        end
        @dynamic_map
      end

      def dynamic_keys
        @dynamic_keys ||= dynamic_parts.map{|dp| dp.name} if dynamic?
      end

      def dynamic_required_keys
        @dynamic_required_keys ||= dynamic_parts.select{|dp| !dp.default_value}.map{|dp| dp.name} if dynamic?
      end

      def dynamic?
        @dynamic
      end

      def can_generate_from_keys?(keys)
        if dynamic?
          (dynamic_required_keys - keys).size.zero? ? keys : nil
        end
      end

      def can_generate_from_params?(params)
        if route.router.consider_destination_keys?
          (route.destination.to_a - params.to_a).size.zero?
        end
      end

      # Merges paths for use in generation
      def merge(other_path)
        new_parts = parts + other_path.parts
        Path.new(route, new_parts)
      end

      def generate
        nil
      end

      def generate_from_hash(params = nil)
        generate
      end

      private
      def parts=(parts)
        @parts = parts
        @dynamic = @parts && @parts.any?{|p| p.is_a?(Variable)}
      end
      
      def interpolating_path
        unless @interpolating_path
          @interpolating_path = ''
          parts.each_with_index do |part, index|
            case part
            when String
              @interpolating_path << part
            when Static::Greedy
              @interpolating_path << part.generate_with
            when Variable::Glob
              @interpolating_path << '#{('
              @interpolating_path << "Array(arg#{index})"
              if part.default_value
                @interpolating_path << ' || '
                @interpolating_path << part.default_value.inspect
              end
              @interpolating_path << ').join(route.router.delimiters.first)}'
            when Variable
              @interpolating_path << '#{'
              @interpolating_path << "arg#{index}"
              if part.default_value
                @interpolating_path << ' || '
                @interpolating_path << part.default_value.inspect
              end
              @interpolating_path << '}'
            end
          end
        end
        @interpolating_path
      end
      
      def build_generator
        if parts
          generating_method =  "def generate"
          if dynamic?
            generating_method << "("
            generating_method << dynamic_indicies.map{|di| "arg#{di}"}.join(", ")
            generating_method << ")\n"
            dynamic_indicies.each do |di|
              dp = parts.at(di)
              generating_method << "@parts.at(#{di}).valid!(arg#{di})\n" if dp.validates?
            end
          else
            generating_method << "\n"
          end
        
          generating_method << '"'
          generating_method << interpolating_path
          generating_method << '"'
          generating_method << "\nend\n\n"
          generating_method << "def generate_from_hash(params = nil)\n"
          generating_method << "generate("
          if parts && dynamic?
            generating_method << dynamic_indicies.map { |di|
              dp = parts.at(di)
              arg = "params && params.delete(:#{dp.name}) "
              arg << "|| @parts.at(#{di}).default_value " if dp.default_value
              arg << "|| raise(MissingParameterException.new(\"expected a value for #{dp.name}\"))"
            }.join(', ')
          end
          generating_method << ")\nend\n\n"
          instance_eval generating_method
        end
      end
      
    end
  end
end
