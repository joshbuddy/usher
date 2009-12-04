require File.join('usher', 'route', 'path')
require File.join('usher', 'route', 'util')
require File.join('usher', 'route', 'variable')
require File.join('usher', 'route', 'static')
require File.join('usher', 'route', 'request_method')

class Usher
  class Route
    attr_reader   :paths, :requirements, :conditions, :named, :generate_with, :default_values, :match_partially, :destination
    attr_accessor :parent_route, :router, :recognizable

    class GenerateWith < Struct.new(:scheme, :port, :host)
      def empty?
        scheme.nil? and port.nil? and host.nil?
      end
    end

    def initialize(parsed_paths, router, conditions, requirements, default_values, generate_with, match_partially)
      @router, @requirements, @conditions, @default_values, @match_partially = router, requirements, conditions, default_values, match_partially
      @recognizable = true
      @paths = parsed_paths.collect {|path| Path.new(self, path)}
      @generate_with = GenerateWith.new(generate_with[:scheme], generate_with[:port], generate_with[:host]) if generate_with
    end

    def grapher
      unless @grapher
        @grapher = Grapher.new
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
      if params.nil? || params.empty?
        matching_path = @paths.first
      else
        matching_path = @paths.size == 1 ? @paths.first : grapher.find_matching_path(params)
      end

      if parent_route
        matching_path = parent_route.find_matching_path(params).merge(matching_path)
        matching_path.route = self
      end

      matching_path
    end

    # Sets +options+ on a route. Returns +self+.
    #
    #   Request = Struct.new(:path)
    #   set = Usher.new
    #   route = set.add_route('/test')
    #   route.to(:controller => 'testing', :action => 'index')
    #   set.recognize(Request.new('/test')).first.params => {:controller => 'testing', :action => 'index'}
    def to(options = nil, &block)
      raise "cannot set destination as block and argument" if block_given? && options
      @destination = if block_given?
        block
      else
        options.parent_route = self if options.respond_to?(:parent_route=)
        options
      end
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
