$:.unshift File.dirname(__FILE__)

require 'route/path'
require 'route/variable'
require 'route/request_method'

class Usher
  class Route
    attr_reader :paths, :original_path, :requirements, :conditions, :params
    
    def initialize(original_path, router, options = nil) # :nodoc:
      @original_path = original_path
      @router = router
      @requirements = options && options.delete(:requirements)
      @conditions = options && options.delete(:conditions)
      @default_values = options && options.delete(:default_values)
      @paths = @router.splitter.split(@original_path, @requirements, @default_values).collect {|path| Path.new(self, path)}
      @grapher = Grapher.new
      @grapher.add_route(self)
      
      #FIXME params is poorly named. this shouldn't be an array
      @params = []
    end
    
    def find_matching_path(params)
      @paths.size == 1 ? @paths.first : @grapher.find_matching_path(params)
    end
    
    
    # Sets +options+ on a route. Returns +self+.
    #   
    #   Request = Struct.new(:path)
    #   set = Usher.new
    #   route = set.add_route('/test')
    #   route.to(:controller => 'testing', :action => 'index')
    #   set.recognize(Request.new('/test')).first.params => {:controller => 'testing', :action => 'index'}
    def to(options = nil, &block)
      @params << (block_given? ? block : options)
      self
    end

    # Sets route as referenceable from +name+. Returns +self+.
    #   
    #   set = Usher.new
    #   route = set.add_route('/test').name(:route)
    #   set.generate_url(:route) => '/test'
    def name(name)
      @router.name(name, self)
      self
    end

  end
end
