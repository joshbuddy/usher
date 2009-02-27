$:.unshift File.dirname(__FILE__)

require 'strscan'
require 'set'
require 'usher/node'
require 'usher/route'
require 'usher/grapher'
require 'usher/interface'
require 'usher/exceptions'

class Usher
  attr_reader :tree, :named_routes, :route_count, :routes
  
  SymbolArraySorter = proc {|a,b| a.hash <=> b.hash}
  Version = '0.0.1'
    
  def empty?
    @route_count.zero?
  end

  def reset!
    @tree = Node.root
    @named_routes = {}
    @routes = []
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
    @named_routes[name] = route.primary_path
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
    @routes << route
    Grapher.instance.add_route(route)
    @route_count += 1
    route
  end

  def recognize(request)
    path = Route::Splitter.new(request.path, request.method).paths.first
    @tree.find(path)
  end

  def route_for_options(options)
    Grapher.instance.find_matching_path(options)
  end
  
  def generate_url(route, params)
    path = case route
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
      path.dynamic_parts.collect{|k| params_hash.delete(k.name)}
    when Array
      params
    else
      Array(params)
    end

    generated_path = ""
    
    sep_p = nil
    path.parts.each do |p|
      case p
      when Route::Variable:
        case p.type
        when :*
          generated_path << sep_p.to_s << param_list.shift * '/'
        else
          (dp = param_list.shift) && generated_path << sep_p.to_s << dp.to_s
        end
      when Route::Separator:
        sep_p = p
      when Route::Method:
        # do nothing
      else
        generated_path << sep_p.to_s << p.to_s
      end
    end
    unless params_hash.blank?
      has_query = generated_path[??]
      params_hash.each do |k,v|
        case v
        when Array
          v.each do |v_part|
            generated_path << (has_query ? '&' : has_query = true && '?')
            generated_path << CGI.escape("#{k.to_s}[]")
            generated_path << '='
            generated_path << CGI.escape(v_part.to_s)
          end
        else
          generated_path << (has_query ? '&' : has_query = true && '?')
          generated_path << CGI.escape(k.to_s)
          generated_path << '='
          generated_path << CGI.escape(v.to_s)
        end
      end
    end
    generated_path
  end
end
