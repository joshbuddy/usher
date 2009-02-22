$:.unshift File.dirname(__FILE__)
require 'strscan'
require 'set'
require 'usher/node'
require 'usher/route'
require 'usher/grapher'
require 'usher/interface'

class Usher
  attr_reader :tree, :named_routes, :route_count
  
  SymbolArraySorter = proc {|a,b| a.hash <=> b.hash}
  
  def load(file)
    reset!
    Kernel.load(file)
  end
  
  def empty?
    @route_count.zero?
  end

  def reset!
    @tree = Node.root
    @named_routes = {}
    @route_count = 0
    Grapher.instance.reset!
  end
  alias clear! reset!
  
  def initialize(mode = :rails)
    @mode = mode
    reset!
  end

  def add_named_route(name, path, options = {})
    add_route(path, options).name(name)
  end

  def name(name, route)
    @named_routes[name] = route
  end

  def add_route(path, options = {})
    conditions = options.delete(:conditions) || {}
    requirements = options.delete(:requirements) || {}
    options.delete_if do |k, v|
      if v.is_a?(Regexp)
        requirements[k] = v 
        true
      end
    end
    
    route = Route.new(path, self, {:conditions => conditions, :requirements => requirements}).to(options)
    
    @tree.add(route)
    Grapher.instance.add_route(route)
    @route_count += 1
    route
  end

  def recognize(request)
    path = Route.path_to_route_parts(request.path, request.method)
    (route, params_list) = @tree.find(path)
    request.path_parameters = (params_list.blank? ? route.params : route.params.merge(Hash[*params_list.flatten])).with_indifferent_access
    "#{request.path_parameters[:controller].camelize}Controller".constantize
  end

  def route_for_options(options)
    Grapher.instance.find_matching_route(options)
  end
  
  def generate_url(route, params)
    route = case route
    when Symbol
      @named_routes[route]
    when nil
      route_for_options(params)
    else
      route
    end

    params_hash = {}
    param_list = case params
    when Hash
      params_hash = params
      route.dynamic_parts.collect{|k| params_hash.delete(k.name)}
    when Array
      params
    else
      Array(params)
    end

    path = ""
    
    sep_p = nil
    route.path.each do |p|
      case p
      when Route::Variable:
        case p.type
        when :*
          path << sep_p.to_s << param_list.shift * '/'
        else
          (dp = param_list.shift) && path << sep_p.to_s << dp.to_s
        end
      when Route::Seperator:
        sep_p = p
      when Route::Method:
        # do nothing
      else
        path << sep_p.to_s << p.to_s
      end
    end
    unless params_hash.blank?
      has_query = path[??]
      params_hash.each do |k,v|
        case v
        when Array
          v.each do |v_part|
            path << (has_query ? '&' : has_query = true && '?')
            path << CGI.escape("#{k.to_s}[]")
            path << '='
            path << CGI.escape(v_part.to_s)
          end
        else
          path << (has_query ? '&' : has_query = true && '?')
          path << CGI.escape(k.to_s)
          path << '='
          path << CGI.escape(v.to_s)
        end
      end
    end
    path
  end
end
