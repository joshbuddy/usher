$:.unshift File.dirname(__FILE__)

require 'cgi'
require 'uri'
require 'usher/node'
require 'usher/route'
require 'usher/grapher'
require 'usher/interface'
require 'usher/splitter'
require 'usher/exceptions'
require 'usher/generate'

class Usher
  attr_reader :tree, :named_routes, :route_count, :routes, :splitter, :delimiters
  
  SymbolArraySorter = proc {|a,b| a.hash <=> b.hash} #:nodoc:
  
  # Returns whether the route set is empty
  #   
  #   set = Usher.new
  #   set.empty? => true
  #   set.add_route('/test')
  #   set.empty? => false
  def empty?
    @route_count.zero?
  end

  # Resets the route set back to its initial state
  #   
  #   set = Usher.new
  #   set.add_route('/test')
  #   set.empty? => false
  #   set.reset!
  #   set.empty? => true
  def reset!
    @tree = Node.root(self, @request_methods, @globs_capture_separators)
    @named_routes = {}
    @routes = []
    @route_count = 0
    @grapher = Grapher.new
  end
  alias clear! reset!
  
  # Creates a route set, with options
  # 
  # <tt>:globs_capture_separators</tt>: +true+ or +false+. (default +false+) Specifies whether glob matching will also include separators
  # that are matched.
  # 
  # <tt>:delimiters</tt>: Array of Strings. (default <tt>['/', '.']</tt>). Delimiters used in path separation. Array must be single character strings.
  # 
  # <tt>:valid_regex</tt>: String. (default <tt>'[0-9A-Za-z\$\-_\+!\*\',]+'</tt>). String that can be interpolated into regex to match
  # valid character sequences within path.
  # 
  # <tt>:request_methods</tt>: Array of Symbols. (default <tt>[:protocol, :domain, :port, :query_string, :remote_ip, :user_agent, :referer, :method, :subdomains]</tt>)
  # Array of methods called against the request object for the purposes of matching route requirements.
  def initialize(options = nil)
    @globs_capture_separators = options && options.key?(:globs_capture_separators) ? options.delete(:globs_capture_separators) : false
    @delimiters = options && options.delete(:delimiters) || ['/', '.']
    @valid_regex = options && options.delete(:valid_regex) || '[0-9A-Za-z\$\-_\+!\*\',]+'
    @request_methods = options && options.delete(:request_methods) || [:protocol, :domain, :port, :query_string, :remote_ip, :user_agent, :referer, :method, :subdomains]
    @splitter = Splitter.for_delimiters(@delimiters, @valid_regex)
    reset!
  end

  # Adds a route referencable by +name+. Sett add_route for format +path+ and +options+.
  #   
  #   set = Usher.new
  #   set.add_named_route(:test_route, '/test')
  def add_named_route(name, path, options = nil)
    add_route(path, options).name(name)
  end

  # Attaches a +route+ to a +name+
  #   
  #   set = Usher.new
  #   route = set.add_route('/test')
  #   set.name(:test, route)
  def name(name, route)
    @named_routes[name] = route
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
    conditions = options && options.delete(:conditions) || {}
    requirements = options && options.delete(:requirements) || {}
    default_values = options && options.delete(:default_values) || {}
    if options
      options.delete_if do |k, v|
        if v.is_a?(Regexp) || v.is_a?(Proc)
          requirements[k] = v 
          true
        end
      end
    end
    route = Route.new(path, self, conditions, requirements, default_values)
    route.to(options) if options && !options.empty?
    
    @tree.add(route)
    @routes << route
    @grapher.add_route(route)
    @route_count += 1
    route
  end

  # Recognizes a +request+ and returns +nil+ or an Usher::Node::Response, which is a struct containing a Usher::Route::Path and an array of arrays containing the extracted parameters.
  #   
  #   Request = Struct.new(:path)
  #   set = Usher.new
  #   route = set.add_route('/test')
  #   set.recognize(Request.new('/test')).path.route == route => true
  def recognize(request, path = request.path)
    @tree.find(self, request, @splitter.url_split(path))
  end

  # Recognizes a set of +parameters+ and gets the closest matching Usher::Route::Path or +nil+ if no route exists.
  #   
  #   set = Usher.new
  #   route = set.add_route('/:controller/:action')
  #   set.path_for_options({:controller => 'test', :action => 'action'}) == path.route => true
  def path_for_options(options)
    @grapher.find_matching_path(options)
  end
  
end
