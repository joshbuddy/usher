module ActionController
  module Routing
    class RouteSet
      class Route
        attr_reader :dynamic_parts, :dynamic_map, :dynamic_keys, :dynamic_indicies, :path, :options, :original_path, :dynamic_set
  
        def self.path_to_route_parts(path, *args)
          options = args.extract_options!
          path.insert(0, '/') unless path[0] == ?/
          ss = StringScanner.new(path)
          parts = []
          while (part = ss.scan(/([:\*]?[0-9a-z_]+|\/|\.)/))
            parts << case part[0]
            when ?:
              Variable.new(:':', part[1..(path.size-1)])
            when ?*
              Variable.new(:'*', part[1..(path.size-1)])
            when ?.
              raise unless part.size == 1
              Seperator::Dot
            when ?/
              raise unless part.size == 1
              Seperator::Slash
            else
              part
            end
          end
    
          parts << Method.for(options[:request_method])
          parts
        end
  
  
        def initialize(path, original_path, options = {})
          @path = path
          @original_path = original_path
          @options = options
          @dynamic_parts = @path.select{|p| p.is_a?(Variable)}
          @dynamic_indicies = []
          @path.each_index{|i| @dynamic_indicies << i if @path[i].is_a?(Variable)}
          @dynamic_map = {}
          @dynamic_keys = []
          @dynamic_parts.each{|p| @dynamic_map[@dynamic_keys << p.name] = p }
          @dynamic_set = Set.new(@dynamic_keys)
          raise "route #{original_path} must include a controller" unless @dynamic_keys.include?(:controller) || options.include?(:controller)
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
          attr_reader :type, :name
          def initialize(type, name)
            @type = type
            @name = :"#{name}"
          end
    
          def to_s
            "#{type}#{name}"
          end
        end

        class Method
          private
          attr_reader :name
          def initialize(name)
            @name = name
          end
    
          public
          def self.for(name)
            case name
            when :get:    Get
            when :post:   Post
            when :put:    Put
            when :delete: Delete
            else          Any
            end
          end
    
          def matches(request)
            self.equals?(Any) || request.method.downcase.to_sym == name
          end
    
          Get = Method.new(:get)
          Post = Method.new(:post)
          Put = Method.new(:put)
          Delete = Method.new(:delete)
          Any = Method.new(:*)
    
        end
      end
    end
  end
end