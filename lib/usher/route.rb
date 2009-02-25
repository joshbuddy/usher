class Usher
  class Route
    attr_reader :dynamic_parts, :dynamic_map, :dynamic_indicies, :path, :original_path, :dynamic_set,
      :requirements, :conditions, :request_method, :params
    
    ScanRegex = /([:\*]?[0-9a-z_]+|\/|\.|\(|\))/
    
    def self.path_to_route_parts(path, request_method = nil, requirements = {})
      parts = path[0] == ?/ ? [] : [Seperator::Slash]
      ss = StringScanner.new(path)
      groups = [parts]
      current_group = parts
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

      parts << Method.for(request_method)

      parts
    end

    def initialize(original_path, router, options = {})
      @original_path = original_path
      @router = router
      @requirements = options.delete(:requirements)
      @conditions = options.delete(:conditions)
      @request_method = @conditions && @conditions.delete(:method)
      @path = Route.path_to_route_parts(@original_path, @request_method, requirements)
      @dynamic_indicies = []
      @path.each_index{|i| @dynamic_indicies << i if @path[i].is_a?(Variable)}
      @dynamic_parts = @path.values_at(*@dynamic_indicies)
      @dynamic_map = {}
      @dynamic_parts.each{|p| @dynamic_map[p.name] = p }
      @dynamic_set = Set.new(@dynamic_map.keys)
    end

    def to(options)
      p "options: #{options.inspect}"
      @params = options
      self
    end

    def name(name)
      @router.name(name, self)
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
