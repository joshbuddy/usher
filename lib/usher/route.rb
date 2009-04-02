$:.unshift File.dirname(__FILE__)

require 'route/path'
require 'route/splitter'
require 'route/variable'
require 'route/request_method'

class Usher
  class Route
    attr_reader :paths, :original_path, :requirements, :conditions, :params, :primary_path
    
    def initialize(original_path, router, options = {}) # :nodoc:
      @original_path = original_path
      @router = router
      @requirements = options.delete(:requirements)
      @conditions = options.delete(:conditions)
      @transformers = options.delete(:transformers)
      @paths = Splitter.new(@original_path, @requirements, @transformers).paths.collect {|path| Path.new(self, path)}
      @primary_path = @paths.first
    end
    
    
    # Sets +options+ on a route. Returns +self+.
    #   
    #   Request = Struct.new(:path)
    #   set = Usher.new
    #   route = set.add_route('/test')
    #   route.to(:controller => 'testing', :action => 'index')
    #   set.recognize(Request.new('/test')).first.params => {:controller => 'testing', :action => 'index'}
    def to(options)
      @params = options
      self
    end

    # Sets route as referenceable from +name+. Returns +self+.
    #   
    #   set = Usher.new
    #   route = set.add_route('/test').name(:route)
    #   set.generate_url(:route) => '/test'
    def name(name)
      @router.name(name, self)
    end

  end
end
