$:.unshift File.dirname(__FILE__)

require 'usher/node'
require 'usher/route'
require 'usher/grapher'
require 'usher/interface'
require 'usher/splitter'
require 'usher/exceptions'

class Usher
  attr_reader :tree, :named_routes, :route_count, :routes, :splitter
  
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
    @tree = Node.root(self)
    @named_routes = {}
    @routes = []
    @route_count = 0
    @grapher = Grapher.new
  end
  alias clear! reset!
  
  # Creates a route set
  def initialize(delimiter = '/')
    @splitter = Splitter.delimiter(delimiter)
    reset!
  end

  # Adds a route referencable by +name+. Sett add_route for format +path+ and +options+.
  #   
  #   set = Usher.new
  #   set.add_named_route(:test_route, '/test')
  def add_named_route(name, path, options = {})
    add_route(path, options).name(name)
  end

  # Attaches a +route+ to a +name+
  #   
  #   set = Usher.new
  #   route = set.add_route('/test')
  #   set.name(:test, route)
  def name(name, route)
    @named_routes[name] = route.primary_path
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
  # ==== Static
  #
  # Static parts of literal character sequences. For instance, <tt>/path/something.html</tt> would match only the same path.
  #
  # ==== Optional sections
  #
  # Sections of a route can be marked as optional by surrounding it with brackets. For instance, in the above static example, <tt>/path/something(.html)</tt> would match both <tt>/path/something</tt> and <tt>/path/something.html</tt>.
  #
  # ==== One and only one sections
  #
  # Sections of a route can be marked as "one and only one" by surrounding it with brackets and separating parts of the route with pipes. For instance, the path, <tt>/path/something(.xml|.html)</tt> would only match <tt>/path/something.xml</tt> and <tt>/path/something.html</tt>.
  #
  # === +options+
  # * +transformers+ - Transforms a variable before it gets to the requirements. Takes either a +proc+ or a +symbol+. If its a +symbol+, calls the method on the incoming parameter. If its a +proc+, its called with the variable.
  # * +requirements+ - After transformation, tests the condition using ===. If it returns false, it raises an <tt>Usher::ValidationException</tt>
  # * +conditions+ - Accepts any of the following <tt>:protocol</tt>, <tt>:domain</tt>, <tt>:port</tt>, <tt>:query_string</tt>, <tt>:remote_ip</tt>, <tt>:user_agent</tt>, <tt>:referer</tt> and <tt>:method</tt>. This can be either a <tt>string</tt> or a regular expression.
  # * Any other key is interpreted as a requirement for the variable of its name.
  def add_route(path, options = {})
    transformers = options.delete(:transformers) || {}
    conditions = options.delete(:conditions) || {}
    requirements = options.delete(:requirements) || {}
    options.delete_if do |k, v|
      if v.is_a?(Regexp)
        requirements[k] = v 
        true
      end
    end
    
    route = Route.new(path, self, {:transformers => transformers, :conditions => conditions, :requirements => requirements}).to(options)
    
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
  def recognize(request)
    @tree.find(request, @splitter.url_split(request.path))
  end

  # Recognizes a set of +parameters+ and gets the closest matching Usher::Route::Path or +nil+ if no route exists.
  #   
  #   set = Usher.new
  #   route = set.add_route('/:controller/:action')
  #   set.route_for_options({:controller => 'test', :action => 'action'}) == path.route => true
  def route_for_options(options)
    @grapher.find_matching_path(options)
  end
  
  # Generates a completed URL based on a +route+ or set of optional +params+
  #   
  #   set = Usher.new
  #   route = set.add_named_route(:test_route, '/:controller/:action')
  #   set.generate_url(nil, {:controller => 'c', :action => 'a'}) == '/c/a' => true
  #   set.generate_url(:test_route, {:controller => 'c', :action => 'a'}) == '/c/a' => true
  #   set.generate_url(route.primary_path, {:controller => 'c', :action => 'a'}) == '/c/a' => true
  def generate_url(route, params = {}, options = {})
    check_variables = options.key?(:check_variables) ? options.delete(:check_variables) : false

    path = case route
    when Symbol
      @named_routes[route]
    when nil
      route_for_options(params)
    when Route
      route.paths.first
    else
      route
    end
    
    params_hash = {}
    param_list = case params
    when Hash
      params_hash = params
      path.dynamic_parts.collect{|k| params_hash.delete(k.name) {|el| raise MissingParameterException.new(k.name)} }
    when Array
      path.dynamic_parts.size == params.size ? params : raise(MissingParameterException.new("got #{params.size} arguments, expected #{path.dynamic_parts.size}"))
    else
      Array(params)
    end

    generated_path = ''
    
    path.parts.each do |p|
      case p
      when Route::Variable
        case p.type
        when :*
          param_list.first.each {|dp| p.valid!(dp.to_s) } if check_variables
          generated_path << '/' << param_list.shift.collect{|dp| dp.to_s} * '/'
        when :'.:'
          p.valid!(param_list.first.to_s) if check_variables
          (dp = param_list.shift) && generated_path << '.' << dp.to_s
        else
          p.valid!(param_list.first.to_s) if check_variables
          (dp = param_list.shift) && generated_path << '/' << dp.to_s
        end
      else
        generated_path << '/' << p.to_s
      end
    end
    unless params_hash.empty?
      has_query = generated_path[??]
      params_hash.each do |k,v|
        case v
        when Array
          v.each do |v_part|
            generated_path << (has_query ? '&' : has_query = true && '?') << CGI.escape("#{k.to_s}[]") << '=' << CGI.escape(v_part.to_s)
          end
        else
          generated_path << (has_query ? '&' : has_query = true && '?') << CGI.escape(k.to_s) << '=' << CGI.escape(v.to_s)
        end
      end
    end
    generated_path
  end
end
