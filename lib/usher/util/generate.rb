require 'rack'

unless Rack::Utils.respond_to?(:uri_escape)
  module Rack

    module Utils

      def uri_escape(s)
        s.to_s.gsub(/([^:\/?\[\]\-_~\.!\$&'\(\)\*\+,;=@a-zA-Z0-9]+)/n) {
          '%'<<$1.unpack('H2'*$1.size).join('%').upcase
        }.tr(' ', '+')
      end
      module_function :uri_escape

      def uri_unescape(s)
        gsub(/((?:%[0-9a-fA-F]{2})+)/n){
          [$1.delete('%')].pack('H*')
        }
      end
      module_function :uri_unescape

    end
  end
end

class Usher
  module Util
    class Generators
    
      class URL
      
        def initialize(usher)
          @usher = usher
        end

        def generate_full(routing_lookup, request, params = nil)
          path = path_for_routing_lookup(routing_lookup, params)
          result = generate_start(path, request)
          result << generate_path(path, params)
        end

        def generate(routing_lookup, params = nil)
          generate_path(path_for_routing_lookup(routing_lookup, params), params)
        end

        def generate_start(path, request)
          result = (path.route.generate_with && path.route.generate_with.scheme || request.scheme).dup
          result << '://'
          result << (path.route.generate_with && path.route.generate_with.host) ? path.route.generate_with.host : request.host
          port = path.route.generate_with && path.route.generate_with.port || request.port
          if result[4] == ?s
            result << ':' << port.to_s if port != 443
          else
            result << ':' << port.to_s if port != 80
          end
          result
        end

        def path_for_routing_lookup(routing_lookup, params)
          path = case routing_lookup
          when Symbol
            route = @usher.named_routes[routing_lookup] 
            params.is_a?(Hash) ? route.find_matching_path(params) : route.paths.first
          when Route
            params.is_a?(Hash) ? routing_lookup.find_matching_path(params) : routing_lookup.paths.first
          when nil
            params.is_a?(Hash) ? @usher.path_for_options(params) : raise
          when Route::Path
            routing_lookup
          end
        end
    
        # Generates a completed URL based on a +route+ or set of optional +params+
        #   
        #   set = Usher.new
        #   route = set.add_named_route(:test_route, '/:controller/:action')
        #   set.generate_url(nil, {:controller => 'c', :action => 'a'}) == '/c/a' => true
        #   set.generate_url(:test_route, {:controller => 'c', :action => 'a'}) == '/c/a' => true
        #   set.generate_url(route.primary_path, {:controller => 'c', :action => 'a'}) == '/c/a' => true
        def generate_path(path, params = nil)
          raise UnrecognizedException.new unless path

          params = Array(params) if params.is_a?(String)
          if params.is_a?(Array)
            given_size = params.size
            extra_params = params.last.is_a?(Hash) ? params.pop : nil
            params = Hash[*path.dynamic_parts.inject([]){|a, dynamic_part| a.concat([dynamic_part.name, params.shift || raise(MissingParameterException.new("got #{given_size}, expected #{path.dynamic_parts.size} parameters"))]); a}]
            params.merge!(extra_params) if extra_params
          end

          result = ''
          path.parts.each do |part|
            case part
            when Route::Variable
              value = (params && params.delete(part.name)) || part.default_value || raise(MissingParameterException.new)
              case part.type
              when :*
                value.each_with_index do |current_value, index|
                  current_value = current_value.to_s unless current_value.is_a?(String)
                  part.valid!(current_value)
                  result << current_value
                  result << '/' if index != value.size - 1
                end
              when :':'
                value = value.to_s unless value.is_a?(String)
                part.valid!(value)
                result << value
              end
            else
              result << part
            end
          end
          result = Rack::Utils.uri_escape(result)

          if params && !params.empty?
            has_query = result[??]
            params.each do |k,v|
              case v
              when Array
                v.each do |v_part|
                  result << (has_query ? '&' : has_query = true && '?') << Rack::Utils.escape("#{k.to_s}[]") << '=' << Rack::Utils.escape(v_part.to_s)
                end
              else
                result << (has_query ? '&' : has_query = true && '?') << Rack::Utils.escape(k.to_s) << '=' << Rack::Utils.escape(v.to_s)
              end
            end
          end
          result
        end
      end
    end
  end
end