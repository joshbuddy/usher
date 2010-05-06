class Usher
  module Util
    class Generators

      class Generic
        attr_accessor :usher

        def generate(name, params)
          generate_path_for_base_params(@usher.named_routes[name].find_matching_path(params), params)
        end

        def generate_path_for_base_params(path, params)
          raise UnrecognizedException.new unless path
          case params
          when nil, Hash
            path.generate_from_hash(params)
          else
            path.generate(*Array(params).slice!(0, path.dynamic_parts.size))
          end
        end
      end

      class URL < Generic

        class UrlParts < Struct.new(:path, :request)
          def scheme
            @scheme ||= generate_with(:scheme) || (request.respond_to?(:scheme) and request.scheme)
          end

          def protocol
            @protocol ||= scheme ? "#{scheme}://" : request.protocol
          end

          def host
            @host ||= generate_with(:host) || request.host
          end

          def port
            @port ||= generate_with(:port) || request.port
          end

          def port_string
            @port_string ||= standard_port? ? '' : ":#{port}"
          end

          def url            
            path.route.generate_with.nil? || path.route.generate_with.empty? ?
              request.url :
              protocol + host + port_string
          end

        protected

          def generate_with(property)
            path.route.generate_with and path.route.generate_with[property]
          end

          def standard_port?
            ssl? ? port == 443 : port == 80
          end

          def ssl?
            protocol[0..4] == 'https'
          end
        end

        def initialize
          require File.join('usher', 'util', 'rack-mixins')
        end

        def generate_full(routing_lookup, request, params = nil)
          path = path_for_routing_lookup(routing_lookup, params)

          result = generate_start(path, request)          
          result << generate_path(path, params)
        end

        # Generates a completed URL based on a `route` or set of optional `params`
        #
        #   set = Usher.new
        #   route = set.add_named_route(:test_route, '/:controller/:action')
        #   set.generator.generate(nil, {:controller => 'c', :action => 'a'}) == '/c/a' => true
        #   set.generator.generate(:test_route, {:controller => 'c', :action => 'a'}) == '/c/a' => true
        #   set.generator.generate(route.primary_path, {:controller => 'c', :action => 'a'}) == '/c/a' => true
        def generate(routing_lookup, params = nil)
          generate_path(path_for_routing_lookup(routing_lookup, params), params)
        end

        def generate_path(path, params = nil, generate_extra = true)
          params = Array(params) if params.is_a?(String)
          extra_params = nil
          case params
          when nil
            params = path && path.route.default_values
          when Hash
            params = path.route.default_values.merge(params) if path && path.route.default_values
          else
            params = Array(params)
            extra_params = params.last.is_a?(Hash) ? params.pop : nil
            raise MissingParameterException.new("got #{params.size}, expected #{path.dynamic_parts.size} parameters") unless path.dynamic_parts.size == params.size
          end
          result = generate_path_for_base_params(path, params)
          Rack::Utils.uri_escape!(result)
          
          params = extra_params if extra_params
          
          if generate_extra && params && !params.empty?
            if usher.consider_destination_keys? && path.route.destination_keys
              params.delete_if{|k, v| path.route.destination_keys.include?(k)}
            end
            result << '?' << generate_querystring(params) unless params.empty?
          end
          result
        end

        def generation_module
          build_module!
          @generation_module
        end

        def build_module!
          unless @generation_module
            @generation_module = Module.new
            @generation_module.module_eval <<-END_EVAL
              @@generator = nil
              def self.generator=(generator)
                @@generator = generator
              end
            END_EVAL
            @generation_module.generator = self

            @generation_module.module_eval <<-END_EVAL
              def respond_to?(method_name)
                if method_name =~ /^(.*?)_(path|url)$/
                  @@generator.usher.named_routes.key?($1)
                else
                  super
                end
              end
            END_EVAL


            usher.named_routes.each do |name, route|
              @generation_module.module_eval <<-END_EVAL
                def #{name}_url(options={})
                  @@generator.generate_full('#{name}'.to_sym, request, options)
                end

                def #{name}_path(options={})
                  @@generator.generate('#{name}'.to_sym, options)
                end
              END_EVAL
            end
          end
        end

        def generate_base_url(params = nil)
          if usher.parent_route
            usher.parent_route.router.generator.generate_path(usher.parent_route.paths.first, params, false)
          elsif params && params.key?(:default)
            params[:default].to_s
          else
            '/'
          end
        end

        def generate_start(path, request)          
          url_parts = UrlParts.new(path, request)
          url = url_parts.url

          (url[-1] == ?/) ? url[0..-2] : url
        end

        def generate_querystring(params)
          extra_params_result = ''
          params.each do |k,v|
            case v
            when Array
              v.each do |v_part|
                extra_params_result << '&' unless extra_params_result.empty?
                extra_params_result << Rack::Utils.escape(k.to_s) << '%5B%5D=' << Rack::Utils.escape(v_part.to_s)
              end
            else
              extra_params_result << '&' unless extra_params_result.empty?
              extra_params_result << Rack::Utils.escape(k.to_s) << '=' << Rack::Utils.escape(v.to_s)
            end
          end
          extra_params_result
        end


        def path_for_routing_lookup(routing_lookup, params = {})
          path = case routing_lookup
          when Route::Path
            routing_lookup
          when Symbol
            route = @usher.named_routes[routing_lookup]
            raise UnrecognizedException unless route
            route.find_matching_path(params || {})
          when Route
            routing_lookup.find_matching_path(params)
          when nil
            params.is_a?(Hash) ? usher.path_for_options(params) : raise
          end
        end
      end
    end
  end
end

