$: << File.expand_path(File.dirname(__FILE__))
require File.join('usher', 'node')
require File.join('usher', 'route')
require File.join('usher', 'grapher')
require File.join('usher', 'interface')
require File.join('usher', 'splitter')
require File.join('usher', 'exceptions')
require File.join('usher', 'util')
require File.join('usher', 'spinoffs', 'strscan_additions')
require File.join('usher', 'delimiters')

class Usher
  attr_reader :root, :named_routes, :routes, :splitter,
              :delimiters, :delimiters_regex,
              :parent_route, :generator, :grapher

  # Returns whether the route set is empty
  #
  #   set = Usher.new
  #   set.empty? => true
  #   set.add_route('/test')
  #   set.empty? => false
  def empty?
    @routes.empty?
  end

  def route_count
    @routes.size
  end

  # Resets the route set back to its initial state
  #
  #   set = Usher.new
  #   set.add_route('/test')
  #   set.empty? => false
  #   set.reset!
  #   set.empty? => true
  def reset!
    @root = Node.root(self, request_methods)
    @named_routes = {}
    @routes = []
    @grapher = Grapher.new
  end
  alias clear! reset!

  # Creates a route set, with options
  #
  # <tt>:delimiters</tt>: Array of Strings. (default <tt>['/', '.']</tt>). Delimiters used in path separation. Array must be single character strings.
  #
  # <tt>:valid_regex</tt>: String. (default <tt>'[0-9A-Za-z\$\-_\+!\*\',]+'</tt>). String that can be interpolated into regex to match
  # valid character sequences within path.
  #
  # <tt>:request_methods</tt>: Array of Symbols. (default <tt>[:protocol, :domain, :port, :query_string, :remote_ip, :user_agent, :referer, :method, :subdomains]</tt>)
  # Array of methods called against the request object for the purposes of matching route requirements.
  def initialize(options = nil)
    self.generator       = options && options.delete(:generator)
    self.delimiters      = Delimiters.new(options && options.delete(:delimiters) || ['/', '.'])
    self.valid_regex     = options && options.delete(:valid_regex) || '[0-9A-Za-z\$\-_\+!\*\',]+'
    self.request_methods = options && options.delete(:request_methods)
    reset!
  end

  def parser
    @parser ||= Util::Parser.for_delimiters(self, valid_regex)
  end

  def can_generate?
    !@generator.nil?
  end

  def generator
    @generator
  end

  # Adds a route referencable by +name+. See add_route for format +path+ and +options+.
  #
  #   set = Usher.new
  #   set.add_named_route(:test_route, '/test')
  def add_named_route(name, path, options = nil)
    add_route(path, options).name(name)
  end

  # Deletes a route referencable by +name+. At least the path and conditions have to match the route you intend to delete.
  #
  #   set = Usher.new
  #   set.delete_named_route(:test_route, '/test')
  def delete_named_route(name, path, options = nil)
    delete_route(path, options)
    @named_routes.delete(name)
  end

  # Attaches a +route+ to a +name+
  #
  #   set = Usher.new
  #   route = set.add_route('/test')
  #   set.name(:test, route)
  def name(name, route)
    @named_routes[name.to_sym] = route
    route
  end

  # Creates a route from +path+ and +options+
  #
  # === +path+
  # A path consists a mix of dynamic and static parts delimited by <tt>/</tt>
  #
  # ==== Dynamic
  # Dynamic parts are prefixed with either :, *.  :variable matches only one part of the path, whereas *variable can match one or
  # more parts.
  #
  # <b>Example:</b>
  # <tt>/path/:variable/path</tt> would match
  #
  # * <tt>/path/test/path</tt>
  # * <tt>/path/something_else/path</tt>
  # * <tt>/path/one_more/path</tt>
  #
  # In the above examples, 'test', 'something_else' and 'one_more' respectively would be bound to the key <tt>:variable</tt>.
  # However, <tt>/path/test/one_more/path</tt> would not be matched.
  #
  # <b>Example:</b>
  # <tt>/path/*variable/path</tt> would match
  #
  # * <tt>/path/one/two/three/path</tt>
  # * <tt>/path/four/five/path</tt>
  #
  # In the above examples, ['one', 'two', 'three'] and ['four', 'five'] respectively would be bound to the key :variable.
  #
  # As well, variables can have a regex matcher.
  #
  # <b>Example:</b>
  # <tt>/product/{:id,\d+}</tt> would match
  #
  # * <tt>/product/123</tt>
  # * <tt>/product/4521</tt>
  #
  # But not
  # * <tt>/product/AE-35</tt>
  #
  # As well, the same logic applies for * variables as well, where only parts matchable by the supplied regex will
  # actually be bound to the variable
  #
  # Variables can also have a greedy regex matcher. These matchers ignore all delimiters, and continue matching for as long as much as their
  # regex allows.
  #
  # <b>Example:</b>
  # <tt>/product/{!id,hello/world|hello}</tt> would match
  #
  # * <tt>/product/hello/world</tt>
  # * <tt>/product/hello</tt>
  #
  # ==== Static
  #
  # Static parts of literal character sequences. For instance, <tt>/path/something.html</tt> would match only the same path.
  # As well, static parts can have a regex pattern in them as well, such as <tt>/path/something.{html|xml}</tt> which would match only
  # <tt>/path/something.html</tt> and <tt>/path/something.xml</tt>
  #
  # ==== Optional sections
  #
  # Sections of a route can be marked as optional by surrounding it with brackets. For instance, in the above static example, <tt>/path/something(.html)</tt> would match both <tt>/path/something</tt> and <tt>/path/something.html</tt>.
  #
  # ==== One and only one sections
  #
  # Sections of a route can be marked as "one and only one" by surrounding it with brackets and separating parts of the route with pipes.
  # For instance, the path, <tt>/path/something(.xml|.html)</tt> would only match <tt>/path/something.xml</tt> and
  # <tt>/path/something.html</tt>. Generally its more efficent to use one and only sections over using regex.
  #
  # === +options+
  # * +requirements+ - After transformation, tests the condition using ===. If it returns false, it raises an <tt>Usher::ValidationException</tt>
  # * +conditions+ - Accepts any of the +request_methods+ specificied in the construction of Usher. This can be either a <tt>string</tt> or a regular expression.
  # * Any other key is interpreted as a requirement for the variable of its name.
  def add_route(path, options = nil)
    route = get_route(path, options)
    @root.add(route)
    @routes << route
    @grapher.add_route(route)
    route.parent_route = parent_route if parent_route
    route
  end

  # Deletes a route. At least the path and conditions have to match the route you intend to delete.
  #
  #   set = Usher.new
  #   set.delete_route('/test')
  def delete_route(path, options = nil)
    route = get_route(path, options)
    @root.delete(route)
    @routes = @root.unique_routes
    rebuild_grapher!
    route
  end

  # Recognizes a +request+ and returns +nil+ or an Usher::Node::Response, which is a struct containing a Usher::Route::Path and an array of arrays containing the extracted parameters.
  #
  #   Request = Struct.new(:path)
  #   set = Usher.new
  #   route = set.add_route('/test')
  #   set.recognize(Request.new('/test')).path.route == route => true
  def recognize(request, path = request.path)
    @root.find(self, request, path, @splitter.url_split(path))
  end

  # Recognizes a +path+ and returns +nil+ or an Usher::Node::Response, which is a struct containing a Usher::Route::Path and an array of arrays containing the extracted parameters. Convenience method for when recognizing on the request object is unneeded.
  #
  #   Request = Struct.new(:path)
  #   set = Usher.new
  #   route = set.add_route('/test')
  #   set.recognize_path('/test').path.route == route => true
  def recognize_path(path)
    recognize(nil, path)
  end

  # Recognizes a set of +parameters+ and gets the closest matching Usher::Route::Path or +nil+ if no route exists.
  #
  #   set = Usher.new
  #   route = set.add_route('/:controller/:action')
  #   set.path_for_options({:controller => 'test', :action => 'action'}) == path.route => true
  def path_for_options(options)
    @grapher.find_matching_path(options)
  end

  def parent_route=(route)
    @parent_route = route
    routes.each{|r| r.parent_route = route}
  end

  def dup
    replacement = super
    original = self
    inverted_named_routes = original.named_routes.invert
    replacement.instance_eval do
      @parser = nil
      reset!
      original.routes.each do |route|
        new_route = route.dup
        new_route.router = self
        @root.add(new_route)
        @routes << new_route
        if name = inverted_named_routes[route]
          @named_routes[name] = new_route
        end
      end
      send(:generator=, original.generator.class.new) if original.can_generate?
      rebuild_grapher!
    end
    replacement
  end

  private

  attr_accessor :request_methods
  attr_reader :valid_regex

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
    @splitter = Splitter.for_delimiters(self.delimiters)
    @valid_regex
  end

  def get_route(path, options = nil)
    conditions = options && options.delete(:conditions) || nil
    requirements = options && options.delete(:requirements) || nil
    default_values = options && options.delete(:default_values) || nil
    generate_with = options && options.delete(:generate_with) || nil
    if options
      options.delete_if do |k, v|
        if v.is_a?(Regexp) || v.is_a?(Proc)
          (requirements ||= {})[k] = v
          true
        end
      end
    end

    if conditions
      conditions.keys.all?{|k| request_methods.include?(k)} or raise
    end

    route = parser.generate_route(path, conditions, requirements, default_values, generate_with)
    route.to(options) if options && !options.empty?
    route
  end

  def rebuild_grapher!
    @grapher = Grapher.new
    @routes.each{|r| @grapher.add_route(r)}
  end
end
