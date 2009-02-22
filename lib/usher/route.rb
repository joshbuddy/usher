class Usher
  class Route
    attr_reader :dynamic_parts, :dynamic_map, :dynamic_indicies, :path, :original_path, :dynamic_set,
      :requirements, :conditions, :request_method, :params
    
    ScanRegex = /([:\*]?[0-9a-z_]+|\/|\.)/
    
    def self.path_to_route_parts(path, request_method = nil, requirements = {})
      parts = path[0] == ?/ ? [] : [Seperator::Slash]
      ss = StringScanner.new(path)
      
      while !ss.eos?
        part = ss.scan(ScanRegex)
        parts << case part[0]
        when ?*, ?:
          type = part.slice!(0).chr.to_sym
          Variable.new(type, part, requirements[part.to_sym])
        when ?.
          Seperator::Dot
        when ?/
          Seperator::Slash
        else
          part
        end
      end unless path.blank? 

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
      @params = options
      raise "route #{original_path} must include a controller" unless @dynamic_set.include?(:controller) || @params.include?(:controller)
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
