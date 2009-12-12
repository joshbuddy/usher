require File.join('usher', 'route', 'path')
require File.join('usher', 'route', 'util')
require File.join('usher', 'route', 'variable')
require File.join('usher', 'route', 'static')
require File.join('usher', 'route', 'request_method')

class Usher
  class Route
    attr_reader   :paths, :requirements, :conditions, :named, :generate_with, :default_values, :match_partially, :destination, :priority
    attr_accessor :parent_route, :router, :recognizable

    class GenerateWith < Struct.new(:scheme, :port, :host)
      def empty?
        scheme.nil? and port.nil? and host.nil?
      end
    end

    def initialize(parsed_paths, router, conditions, requirements, default_values, generate_with, match_partially, priority)
      @router, @requirements, @conditions, @default_values, @match_partially, @priority = router, requirements, conditions, default_values, match_partially, priority
      @recognizable = true
      @paths = parsed_paths.collect {|path| Path.new(self, path)}
      @generate_with = GenerateWith.new(generate_with[:scheme], generate_with[:port], generate_with[:host]) if generate_with
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

    def grapher
      unless @grapher
        @grapher = Grapher.new(router)
        @grapher.add_route(self)
      end
      @grapher
    end
    
    def unrecognizable!
      self.recognizable = false
      self
    end

    def recognizable!
      self.recognizable = true
      self
    end

    def recognizable?
      self.recognizable
    end
    
    def dup
      result = super
      result.instance_eval do
        @grapher = nil
      end
      result
    end

    def find_matching_path(params)
      #if router.find_matching_paths_based_on_destination_keys?
      matching_path = if params.nil? || params.empty?
        @paths.first
      else
        @paths.size == 1 ? @paths.first : grapher.find_matching_path(params)
      end
      
      if matching_path.nil? and router.find_matching_paths_based_on_destination_keys?
        # do something
      end
      
      if parent_route
        matching_path = parent_route.find_matching_path(params).merge(matching_path)
        matching_path.route = self
      end

      matching_path
    end

    CompoundDestination = Struct.new(:args, :block, :options)

    # Sets +options+ on a route. Returns +self+.
    #
    #   Request = Struct.new(:path)
    #   set = Usher.new
    #   route = set.add_route('/test')
    #   route.to(:controller => 'testing', :action => 'index')
    #   set.recognize(Request.new('/test')).first.params => {:controller => 'testing', :action => 'index'}
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

    # Sets route as referenceable from +name+. Returns +self+.
    #
    #   set = Usher.new
    #   route = set.add_route('/test').name(:route)
    #   set.generate_url(:route) => '/test'
    def name(name)
      @named = name
      @router.name(name, self)
      self
    end

    def match_partially!
      @match_partially = true
      self
    end

    def partial_match?
      @match_partially
    end

    private
    attr_writer :grapher

  end
end
