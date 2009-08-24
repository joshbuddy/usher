require File.join(File.dirname(__FILE__), 'route', 'path')
require File.join(File.dirname(__FILE__), 'route', 'util')
require File.join(File.dirname(__FILE__), 'route', 'variable')
require File.join(File.dirname(__FILE__), 'route', 'request_method')

class Usher
  class Route
    attr_reader   :paths, :requirements, :conditions, :destination, :named, :generate_with, :default_values
    attr_accessor :parent_route
    
    GenerateWith = Struct.new(:scheme, :port, :host)
    
    def initialize(parsed_paths, router, conditions, requirements, default_values, generate_with, match_partially) # :nodoc:
      @router = router
      @requirements = requirements
      @conditions = conditions
      @default_values = default_values
      @generate_with = GenerateWith.new(generate_with[:scheme], generate_with[:port], generate_with[:host]) if generate_with
      @paths = parsed_paths.collect {|path| Path.new(self, path)}
      @match_partially = match_partially
    end
    
    def grapher
      unless @grapher
        @grapher = Grapher.new
        @grapher.add_route(self)
      end
      @grapher
    end

    def dup
      result = super
      grapher = Grapher.new
      grapher.add_route(self)
      result.instance_variable_set("@grapher", grapher)
      result
    end

    def find_matching_path(params)
      if params.nil? || params.empty?
        matching_path = @paths.first
      else
        matching_path = @paths.size == 1 ? @paths.first : grapher.find_matching_path(params)
      end
      
      unless parent_route.nil?
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
      @destination = if options.respond_to?(:parent_route=)
        options.parent_route = self
        options
      else
        block_given? ? block : options
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

  end
end
