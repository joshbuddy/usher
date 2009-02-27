$:.unshift File.dirname(__FILE__)

require 'route/path'
require 'route/splitter'
require 'route/separator'
require 'route/variable'
require 'route/method'

class Usher
  class Route
    attr_reader :paths, :original_path, :requirements, :conditions, :request_method, :params, :primary_path
    
    def initialize(original_path, router, options = {})
      @original_path = original_path
      @router = router
      @requirements = options.delete(:requirements)
      @conditions = options.delete(:conditions)
      @request_method = @conditions && @conditions.delete(:method)
      @paths = Splitter.new(@original_path, @request_method, requirements).paths.collect { |path| Path.new(self, path)}
      @primary_path = @paths.first
    end

    def to(options)
      @params = options
      self
    end

    def name(name)
      @router.name(name, self)
    end

  end
end
