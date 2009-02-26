class Usher
  class Route
    attr_reader :dynamic_parts, :dynamic_map, :dynamic_indicies, :path, :original_path, :dynamic_set,
      :requirements, :conditions, :request_method, :params, :alternate_routes
    
    def initialize(original_path, router, options = {})
      @original_path = original_path
      @router = router
      @requirements = options.delete(:requirements)
      @conditions = options.delete(:conditions)
      @request_method = @conditions && @conditions.delete(:method)
      @path = Split.new(@original_path, @request_method, requirements).paths.first
      @dynamic_indicies = []
      @path.each_index{|i| @dynamic_indicies << i if @path[i].is_a?(Variable)}
      @dynamic_parts = @path.values_at(*@dynamic_indicies)
      @dynamic_map = {}
      @dynamic_parts.each{|p| @dynamic_map[p.name] = p }
      @dynamic_set = Set.new(@dynamic_map.keys)
      @alternate_routes = []
    end

    def to(options)
      @params = options
      self
    end

    def name(name)
      @router.name(name, self)
    end

    class Split
      ScanRegex = /([:\*]?[0-9a-z_]+|\/|\.|\(|\))/
      
      attr_reader :paths
      
      def initialize(path, request_method = nil, requirements = {})
        @parts = path[0] == ?/ ? [] : [Seperator::Slash]
        ss = StringScanner.new(path)
        groups = [@parts]
        current_group = @parts
        while !ss.eos?
          part = ss.scan(ScanRegex)
          case part[0]
          when ?*, ?:
            type = part.slice!(0).chr.to_sym
            current_group << Variable.new(type, part, requirements[part.to_sym])
          when ?.
            current_group << Seperator::Dot
          when ?/
            current_group << Seperator::Slash
          when ?(
            new_group = []
            groups << new_group
            current_group << new_group
            current_group = new_group
          when ?)
            groups.pop
            current_group = groups.last
          else
            current_group << part
          end
        end unless !path || path.empty?
        @parts << Method.for(request_method)
        @paths = calc_paths(@parts)
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


    class Seperator
      private
      def initialize(sep)
        @sep = sep
        @sep_to_s = "#{sep}"
      end

      public
      def to_s
        @sep_to_s
      end

      Dot = Seperator.new(:'.')
      Slash = Seperator.new(:/)
    end

    class Variable
      attr_reader :type, :name, :validator
      def initialize(type, name, validator = nil)
        @type = type
        @name = :"#{name}"
        @validator = validator
      end

      def to_s
        "#{type}#{name}"
      end
      
      def ==(o)
        o && (o.type == @type && o.name == @name && o.validator == @validator)
      end
    end

    class Method
      private
      attr_reader :name
      def initialize(name = nil)
        @name = name
      end

      public
      def self.for(name)
        name && Methods[name] || Any
      end
      
      Get = Method.new(:get)
      Post = Method.new(:post)
      Put = Method.new(:put)
      Delete = Method.new(:delete)
      Any = Method.new
      
      Methods = {:get => Get, :post => Post, :put => Put, :delete => Delete}
      
    end
  end
end
