require File.join('usher', 'route', 'path')
require File.join('usher', 'route', 'util')
require File.join('usher', 'route', 'variable')
require File.join('usher', 'route', 'static')
require File.join('usher', 'route', 'request_method')

class Usher
  class Route
    attr_reader   :original_path, :paths, :requirements, :conditions, :named, :generate_with, :default_values, :match_partially, :destination, :priority, :when_proc
    attr_accessor :parent_route, :router, :recognizable

    class GenerateWith < Struct.new(:scheme, :port, :host)
      def empty?
        scheme.nil? and port.nil? and host.nil?
      end
    end

    def ==(other_route)
      if other_route.is_a?(Route)
        original_path == other_route.original_path && requirements == other_route.requirements && conditions == other_route.conditions && match_partially == other_route.match_partially && recognizable == other_route.recognizable && parent_route == other_route.parent_route && generate_with == other_route.generate_with
      end
    end

    def initialize(original_path, parsed_paths, router, conditions, requirements, default_values, generate_with, match_partially, priority)
      @original_path, @router, @requirements, @conditions, @default_values, @match_partially, @priority = original_path, router, requirements, conditions, default_values, match_partially, priority
      @recognizable = true
      @paths = parsed_paths.collect {|path| Path.new(self, path)}
      @generate_with = GenerateWith.new(generate_with[:scheme], generate_with[:port], generate_with[:host]) if generate_with
    end

    def when(&block)
      @when_proc = block
      self
    end

    def destination_keys
      @destination_keys ||= case
        when Hash
          destination.keys
        when CompoundDestination
          destination.options.keys
        else
          nil
      end
    end

    def inspect
      "#<Usher:Route:0x%x @paths=[%s]>" % [self.object_id, paths.collect{|p| p.parts ? p.parts.join : 'nil'}.join(', ')]
    end

    def to_s
      inspect
    end

    def grapher
      unless @grapher
        @grapher = Grapher.new(router)
        @grapher.add_route(self)
      end
      @grapher
    end

    def unrecognizable!
      @recognizable = false
      self
    end

    def recognizable!
      @recognizable = true
      self
    end

    def recognizable?
      @recognizable
    end

    def dup
      result = super
      result.instance_eval do
        @grapher = nil
      end
      result
    end

    def find_matching_path(params)
      significant_param_keys = (params && params.is_a?(Hash)) ? (params.keys & grapher.significant_keys) : nil
      matching_path = if significant_param_keys.nil? || significant_param_keys.empty?
        @paths.first
      else
        @paths.size == 1 ? @paths.first : grapher.find_matching_path(params)
      end

      if parent_route
        matching_path = parent_route.find_matching_path(params).merge(matching_path)
        matching_path.route = self
      end

      matching_path
    end

    CompoundDestination = Struct.new(:args, :block, :options)

    # Sets destination on a route.
    # @return [self]
    # @param [Object] args 
    #   If you pass in more than one variable, it will be returned to you wrapped in a {CompoundDestination}
    #   If you send it varargs and the last member is a Hash, it will pop off the hash, and will be stored under {CompoundDestination#options}
    #   Otherwise, if you use send a single variable, or call it with a block, these will be returned to you by {CompoundDestination#destination}
    # @example
    #     Request = Struct.new(:path)
    #     set = Usher.new
    #     route = set.add_route('/test')
    #     route.to(:controller => 'testing', :action => 'index')
    #     set.recognize(Request.new('/test')).first.params => {:controller => 'testing', :action => 'index'}
    #
    #
    #
    def to(*args, &block)
      if !args.empty? && block
        @destination = CompoundDestination.new(args, block, args.last.is_a?(Hash) ? args.pop : {})
      elsif block.nil?
        case args.size
          when 0
            raise "destination should be set as something"
          when 1
            @destination = args.first
          else
            @destination = CompoundDestination.new(args, nil, args.last.is_a?(Hash) ? args.pop : {})
        end
      else
        @destination = block
      end
      args.first.parent_route = self if args.first.respond_to?(:parent_route=)
      self
    end

    # Sets route as referenceable from `name`
    # @param [Symbol] name The name of the route
    # @return [self] The route named
    # @example
    #     set = Usher.new
    #     route = set.add_route('/test').name(:route)
    #     set.generate_url(:route) => '/test'
    def name(name)
      @named = name
      @router.name(name, self)
      self
    end

    def match_partially!
      @match_partially = true
      self
    end

    alias_method :partial_match?, :match_partially

    private
      attr_writer :grapher

  end
end
