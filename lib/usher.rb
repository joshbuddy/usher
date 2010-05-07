require 'fuzzy_hash'

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))
require File.join('usher', 'node')
require File.join('usher', 'route')
require File.join('usher', 'grapher')
require File.join('usher', 'interface')
require File.join('usher', 'splitter')
require File.join('usher', 'exceptions')
require File.join('usher', 'util')
require File.join('usher', 'delimiters')

# Main class for routing.
# If you're going to be routing for a specific context, like rails or rack, you probably want to use an interface. Otherwise, this
# is the main class that actually does all the work.
# @example
#     u = Usher.new
#     u.add_route('one/two').to(:one)
#     u.add_route('two/three').to(:two)
#     u.add_route('two/:variable').to(:variable)
#     u.recognize_path('one/two').destination
#     ==> :one
#     u.recognize_path('two/whatwasthat').params_as_hash
#     ==> {:variable => 'whatwasthat'}
class Usher
  attr_reader   :root, :named_routes, :routes, :splitter,
                :delimiters, :delimiters_regex, :parent_route, :generator, :grapher, :parser
  attr_accessor :route_class
  
  # @return [Boolean] Whether the route set is empty
  # @example
  #     set = Usher.new
  #     set.empty? => true
  #     set.add_route('/test')
  #     set.empty? => false
  def empty?
    routes.empty?
  end

  # @return [Number] The number of routes currently mapped
  #
  def route_count
    routes.size
  end

  # Resets the route set back to its initial state
  # @example
  #     set = Usher.new
  #     set.add_route('/test')
  #     set.empty? => false
  #     set.reset!
  #     set.empty? => true
  def reset!
    @root = class_for_root.new(self, request_methods)
    @named_routes = {}
    @routes = []
    @grapher = Grapher.new(self)
    @priority_lookups = false
    @parser = Util::Parser.new(self, valid_regex)
  end

  # Creates a route set, with options
  # @param [Hash] options the options to create a router with
  # @option options [Array<String>] :delimiters (['/', '.']) Delimiters used in path separation. Array must be single character strings.
  # @option options [String] :valid_regex ('[0-9A-Za-z\$\-_\+!\*\',]+') String that can be interpolated into regex to match valid character sequences within path.
  # @option options [Array<Symbol>] :request_methods ([:protocol, :domain, :port, :query_string, :remote_ip, :user_agent, :referer, :method, :subdomains])  Array of methods called against the request object for the purposes of matching route requirements.
  # @option options [nil or Generator] :generator (nil) Take a look at `Usher::Util::Generators for examples.`.
  # @option options [Boolean] :ignore_trailing_delimiters (false) Ignore trailing delimiters in recognizing paths.
  # @option options [Boolean] :consider_destination_keys (false) When generating, and using hash destinations, you can have Usher use the destination hash to match incoming params.
  # @option options [Boolean] :detailed_failure (false) When a route fails to match, return a {Node::FailedResponse} instead of a `nil`
  #   Example, you create a route with a destination of :controller => 'test', :action => 'action'. If you made a call to generator with :controller => 'test', 
  #   :action => 'action', it would pick that route to use for generation.
  # @option options [Boolean] :allow_identical_variable_names (true) When adding routes, allow identical variable names to be used.
  def initialize(options = nil)
    self.route_class                     = Usher::Route
    self.generator                       = options && options.delete(:generator)
    self.delimiters                      = Delimiters.new(options && options.delete(:delimiters) || ['/', '.'])
    self.valid_regex                     = options && options.delete(:valid_regex) || '[0-9A-Za-z\$\-_\+!\*\',]+'
    self.request_methods                 = options && options.delete(:request_methods)
    self.ignore_trailing_delimiters      = options && options.key?(:ignore_trailing_delimiters) ? options.delete(:ignore_trailing_delimiters) : false
    self.consider_destination_keys       = options && options.key?(:consider_destination_keys) ? options.delete(:consider_destination_keys) : false
    self.allow_identical_variable_names  = options && options.key?(:allow_identical_variable_names) ? options.delete(:allow_identical_variable_names) : true
    self.detailed_failure                = options && options.key?(:detailed_failure) ? options.delete(:detailed_failure) : false

    unless options.nil? || options.empty?
      raise "unrecognized options -- #{options.keys.join(', ')}"
    end
    reset!
  end
  
  # @return [Boolean] State of allow_identical_variable_names feature.
  def allow_identical_variable_names?
    @allow_identical_variable_names
  end
  
  # @return [Boolean] State of detailed_failure feature.
  def detailed_failure?
    @detailed_failure
  end
  
  # @return [Boolean] State of ignore_trailing_delimiters feature.
  def ignore_trailing_delimiters?
    @ignore_trailing_delimiters
  end
  
  # @return [Boolean] State of consider_destination_keys feature.
  def consider_destination_keys?
    @consider_destination_keys
  end

  # @return [Boolean] State of priority_lookups feature.
  def priority_lookups?
    @priority_lookups
  end

  # @return [Boolean] Able to generate
  def can_generate?
    !generator.nil?
  end

  # Adds a route referencable by `name`. See {#add_route} for format `path` and `options`.
  # @param name Name of route
  # @param path Path of route
  # @param options Options for route
  # @return (Route) Route added
  # @example
  #     set = Usher.new
  #     set.add_named_route(:test_route, '/test')
  def add_named_route(name, path, options = nil)
    add_route(path, options).name(name)
  end

  # Deletes a route referencable by `name`. At least the path and conditions have to match the route you intend to delete.
  # @param name Name of route
  # @param path Path of route
  # @param options Options for route
  # @return (Route) Route added
  # @example
  #     set = Usher.new
  #     set.delete_named_route(:test_route, '/test')
  def delete_named_route(name, path, options = nil)
    delete_route(path, options)
    named_routes.delete(name)
  end

  # Attaches a `route` to a `name`
  # @param name Name of route
  # @param route Route to attach to
  # @return (Route) Route named
  # @example
  #     set = Usher.new
  #     route = set.add_route('/test')
  #     set.name(:test, route)
  def name(name, route)
    named_routes[name.to_sym] = route
    route
  end

  # Creates a route from `path` and `options`
  # @param [String] path
  #
  #   A path consists a mix of dynamic and static parts delimited by `/`
  #   ## Dynamic
  #   Dynamic parts are prefixed with either :, *.  :variable matches only one part of the path, whereas *variable can match one or
  #   more parts.
  # 
  #   ### Example
  #   `/path/:variable/path` would match
  #   
  #    *  `/path/test/path`
  #    *  `/path/something_else/path`
  #    *  `/path/one_more/path`
  # 
  #   In the above examples, 'test', 'something_else' and 'one_more' respectively would be bound to the key `:variable`.
  #   However, `/path/test/one_more/path` would not be matched.
  # 
  #   ### example
  #   `/path/*variable/path` would match
  # 
  #    *  `/path/one/two/three/path`
  #    *  `/path/four/five/path` 
  # 
  #   In the above examples, `['one', 'two', 'three']` and `['four', 'five']` respectively would be bound to the key `:variable`.
  # 
  #   As well, variables can have a regex matcher.
  # 
  #   ### Example
  #   `/product/{:id,\d+}` would match
  # 
  #   *  `/product/123`
  #   *  `/product/4521`
  # 
  #   But not
  # 
  #   *  `/product/AE-35`
  # 
  #   As well, the same logic applies for * variables as well, where only parts matchable by the supplied regex will
  #   actually be bound to the variable
  # 
  #   Variables can also have a greedy regex matcher. These matchers ignore all delimiters, and continue matching for as long as much as their
  #   regex allows.
  # 
  #   ### Example
  #   `/product/{!id,hello/world|hello}` would match
  # 
  #   *  `/product/hello/world`
  #   *  `/product/hello`
  # 
  #   ## Static
  # 
  #   Static parts of literal character sequences. For instance, `/path/something.html` would match only the same path.
  #   As well, static parts can have a regex pattern in them as well, such as `/path/something.{html|xml}` which would match only
  #   `/path/something.html` and `/path/something.xml`
  # 
  #   ## Optional sections
  # 
  #   Sections of a route can be marked as optional by surrounding it with brackets. For instance, in the above static example, `/path/something(.html)` would match both `/path/something` and `/path/something.html`.
  # 
  #   ## One and only one sections
  # 
  #   Sections of a route can be marked as "one and only one" by surrounding it with brackets and separating parts of the route with pipes.
  #   For instance, the path, `/path/something(.xml|.html)` would only match `/path/something.xml` and
  #   `/path/something.html`. Generally its more efficent to use one and only sections over using regex.
  #   
  # @param [Hash] options
  #   Any other key is interpreted as a requirement for the variable of its name.
  # @option options [Object] :requirements After transformation, tests the condition using ===. If it returns false, it raises an {ValidationException}
  # @option options [String, Regexp] :conditions Accepts any of the `request_methods` specificied in the construction of Usher. This can be either a `String` or a regular expression.
  # @option options [Hash<Symbol, String>] :default_values Provides values for variables in your route for generation. If you're using URL generation, then any values supplied here that aren't included in your path will be appended to the query string.
  # @option options [Number] :priority If there are two routes which equally match, the route with the highest priority will match first.
  # @return [Route] The route added
  def add_route(path, options = nil)
    route = get_route(path, options)
    root.add(route)
    routes << route
    grapher.add_route(route)
    route.parent_route = parent_route if parent_route
    route
  end

  # Deletes a route. At least the path and conditions have to match the route you intend to delete.
  # @param path [String] The path to delete
  # @param options [Hash] The options used to identify the path
  # @example 
  #      set.delete_route('/test')
  # @return [Route] The route deleted
  def delete_route(path, options = nil)
    route = get_route(path, options)
    root.delete(route)
    routes.replace(root.unique_routes)
    build_grapher!
    route
  end

  def add_meta(meta, path, options = nil)
    route = get_route(path, options)
    root.add_meta(route, meta)
  end

  # Recognizes a `request`
  # @param request [#path] The request object. Must minimally respond to #path if no path argument is supplied here.
  # @param path [String] The path to be recognized.
  # @return [nil, Node::Response] The recognition response if the request object was recognized
  # @example
  #     Request = Struct.new(:path)
  #     set = Usher.new
  #     route = set.add_route('/test')
  #     set.recognize(Request.new('/test')).path.route == route => true
  def recognize(request, path = request.path)
    root.lookup(request, path)
  end

  # Recognizes a `path`
  # @param path [String] The path to be recognized.
  # @return [nil, Node::Response] The recognition response if the request object was recognized
  # @example
  #     Request = Struct.new(:path)
  #     set = Usher.new
  #     route = set.add_route('/test')
  #     set.recognize_path('/test').path.route == route => true
  def recognize_path(path)
    recognize(nil, path)
  end

  # Recognizes a set of `parameters` and gets the closest matching Usher::Route::Path or `nil` if no route exists.
  # @param options [Hash<Symbol, String>] A set of parameters
  # @return [nil, Route::Path] A path matched or `nil` if not found.
  # @example
  #     set = Usher.new
  #     route = set.add_route('/:controller/:action')
  #     set.path_for_options({:controller => 'test', :action => 'action'}) == path.route => true
  def path_for_options(options)
    grapher.find_matching_path(options)
  end

  # The assignes the parent route this router belongs to.
  # @param route [Route] The route to use to assign as this routers parent route
  def parent_route=(route)
    @parent_route = route
    routes.each{|r| r.parent_route = route}
  end

  # Duplicates the router.
  # @return [Usher] The duplicated router
  def dup
    replacement = super
    original = self
    inverted_named_routes = original.named_routes.invert
    replacement.instance_eval do
      reset!
      original.routes.each do |route|
        new_route = route.dup
        new_route.router = self
        root.add(new_route)
        routes << new_route
        if name = inverted_named_routes[route]
          named_routes[name] = new_route
        end
      end
      send(:generator=, original.generator.class.new) if original.can_generate?
      build_grapher!
    end
    replacement
  end

  def inspect
    "#<Usher:0x%x route_count=%d delimiters=%s request_methods=%s ignore_trailing_delimiters? %s consider_destination_keys? %s can_generate? %s priority_lookups? %s>" % [self.object_id, route_count, self.delimiters.inspect, request_methods.inspect, ignore_trailing_delimiters?.inspect, consider_destination_keys?.inspect, can_generate?.inspect, priority_lookups?.inspect]
  end

  def to_s
    inspect
  end

  private

  attr_accessor :request_methods, :ignore_trailing_delimiters, :consider_destination_keys, :allow_identical_variable_names, :detailed_failure
  attr_reader :valid_regex
  attr_writer :parser
  
  def generator=(generator)
    if generator
      @generator = generator
      @generator.usher = self
    end
    @generator
  end

  def delimiters=(delimiters)
    @delimiters = delimiters
    @delimiters_regex = @delimiters.collect{|d| Regexp.quote(d)} * '|'
    @delimiters
  end

  def valid_regex=(valid_regex)
    @valid_regex = valid_regex
    @splitter = Splitter.new(self.delimiters)
    @valid_regex
  end

  def enable_priority_lookups!
    @priority_lookups = true
  end

  # Returns the route this path, options belongs to. Used internally by add_route, delete_route.
  # @see #add_route, #delete_route
  # @param path [String] path
  # @param options [Hash] options
  def get_route(path, options = nil)
    conditions = options && options.delete(:conditions) || nil
    requirements = options && options.delete(:requirements) || nil
    default_values = options && options.delete(:default_values) || nil
    generate_with = options && options.delete(:generate_with) || nil
    priority = options && options.delete(:priority) || nil
    if options
      options.delete_if do |k, v|
        if v.is_a?(Regexp) || v.is_a?(Proc)
          (requirements ||= {})[k] = v
          true
        end
      end
    end

    if conditions && !conditions.empty?
      conditions.keys.all?{|k| request_methods.include?(k)} or raise("You are trying to use request methods that don't exist in the request_methods supplied #{conditions.keys.join(', ')} -> #{(conditions.keys - request_methods).join(", ")}")
    end

    if priority
      enable_priority_lookups!
    end

    route = parser.generate_route(path, conditions, requirements, default_values, generate_with, priority)
    raise(MultipleParameterException.new) if !allow_identical_variable_names? and route.paths.first.dynamic? and route.paths.first.dynamic_keys.uniq.size != route.paths.first.dynamic_keys.size
    route.to(options) if options && !options.empty?
    route
  end

  # Rebuilds the grapher
  def build_grapher!
    @grapher = Grapher.new(self)
    routes.each{|r| grapher.add_route(r)}
  end

  def class_for_root
    ignore_trailing_delimiters? ? Node::RootIgnoringTrailingDelimiters : Node::Root
  end
  
end
