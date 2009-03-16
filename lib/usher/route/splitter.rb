class Usher
  class Route
    class Splitter
      
      ScanRegex = /((:|\*||\.:|)[0-9a-z_]+|\/|\(|\))/
      UrlScanRegex = /\/|\.?\w+/
      
      attr_reader :paths
      
      def initialize(path, requirements = {}, transformers = {})
        @parts = Splitter.split(path, requirements, transformers)
        @paths = calc_paths(@parts)
      end

      def self.url_split(path)
        parts = []
        ss = StringScanner.new(path)
          while !ss.eos?
            if part = ss.scan(UrlScanRegex)
              parts << part unless part == '/'
            end
          end if path && !path.empty?
        parts
      end
      
      def self.split(path, requirements = {}, transformers = {})
        parts = []
        ss = StringScanner.new(path)
        groups = [parts]
        current_group = parts
        while !ss.eos?
          part = ss.scan(ScanRegex)
          case part[0]
          when ?*, ?:, ?.
            type = (part[1] == ?: ? part.slice!(0,2) : part.slice!(0).chr).to_sym
            current_group << Variable.new(type, part, :validator => requirements[part.to_sym], :transformer => transformers[part.to_sym])
          when ?(
            new_group = []
            groups << new_group
            current_group << new_group
            current_group = new_group
          when ?)
            groups.pop
            current_group = groups.last
          when ?/
          else
            current_group << part
          end
        end unless !path || path.empty?
        parts
      end

      private
      def calc_paths(parts)
        paths = []
        optional_parts = []
        parts.each_index {|i| optional_parts << i if parts[i].is_a?(Array)}
        if optional_parts.size.zero?
          [parts]
        else
          (0...(2 << (optional_parts.size - 1))).each do |i|
            current_paths = [[]]
            parts.each_index do |part_index|
              part = parts[part_index]
              if optional_parts.include?(part_index) && (2 << (optional_parts.index(part_index)-1) & i != 0)
                new_sub_parts = calc_paths(part)
                current_paths_size = current_paths.size
                (new_sub_parts.size - 1).times {|i| current_paths << current_paths[i % current_paths_size].dup }
                current_paths.each_index do |current_path_idx|
                  current_paths[current_path_idx].push(*new_sub_parts[current_path_idx % new_sub_parts.size])
                end
              elsif !optional_parts.include?(part_index)
                current_paths.each { |current_path| current_path << part }
              end
            end
            paths.push(*current_paths)
          end
          paths
        end
      end
      
    end
  end
end