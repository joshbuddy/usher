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

          result = ''
          path.parts.each do |part|
            case part
            when Route::Variable::Glob
              value = (params && params.delete(part.name)) || part.default_value || raise(MissingParameterException.new)
              value.each_with_index do |current_value, index|
                part.valid!(current_value)
                result << current_value.to_s
                result << usher.delimiters.first if index != value.size - 1
              end
            when Route::Variable
              value = (params && params.delete(part.name)) || part.default_value || raise(MissingParameterException.new)
              part.valid!(value)
              result << value.to_s
            else
              result << part
            end
          end
          result
        end

      end

      class URL < Generic

        def initialize
          require File.join(File.dirname(__FILE__), 'rack-mixins')
        end

        def generate_full(routing_lookup, request, params = nil)
          path = path_for_routing_lookup(routing_lookup, params)
          result = generate_start(path, request)
          result << generate_path(path, params)
        end

        # Generates a completed URL based on a +route+ or set of optional +params+
        #
        #   set = Usher.new
        #   route = set.add_named_route(:test_route, '/:controller/:action')
        #   set.generator.generate(nil, {:controller => 'c', :action => 'a'}) == '/c/a' => true
        #   set.generator.generate(:test_route, {:controller => 'c', :action => 'a'}) == '/c/a' => true
        #   set.generator.generate(route.primary_path, {:controller => 'c', :action => 'a'}) == '/c/a' => true
        def generate(routing_lookup, params = nil)
          generate_path(path_for_routing_lookup(routing_lookup, params), params)
        end

        def generate_path(path, params = nil)
          params = Array(params) if params.is_a?(String)
          if params.is_a?(Array)
            given_size = params.size
            extra_params = params.last.is_a?(Hash) ? params.pop : nil
            params = Hash[*path.dynamic_parts.inject([]){|a, dynamic_part| a.concat([dynamic_part.name, params.shift || raise(MissingParameterException.new("got #{given_size}, expected #{path.dynamic_parts.size} parameters"))]); a}]
            params.merge!(extra_params) if extra_params
          end

          result = Rack::Utils.uri_escape(generate_path_for_base_params(path, params))
          unless params.nil? || params.empty?
            extra_params = generate_extra_params(params, result[??])
            result << extra_params
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
                if match = Regexp.new('^(.*?)_(path|url)$').match(method_name.to_s)
                  @@generator.usher.named_routes.key?(match.group(1))
                else
                  super
                end
              end
            END_EVAL


            usher.named_routes.each do |name, route|
              @generation_module.module_eval <<-END_EVAL
                def #{name}_url(name, request, params = nil)
                  @@generator.generate_full(name, request, options)
                end

                def #{name}_path(name, params = nil)
                  @@generator.generate(name, options)
                end
              END_EVAL
            end
          end
        end

        def generate_start(path, request)
          result = (path.route.generate_with && path.route.generate_with.scheme || request.scheme).dup
          result << '://'
          result << (path.route.generate_with && path.route.generate_with.host) ? path.route.generate_with.host : request.host
          port = path.route.generate_with && path.route.generate_with.port || request.port
          if result[4] == ?s
            result << ':' << port.to_s unless port == 443
          else
            result << ':' << port.to_s unless port == 80
          end
          result
        end

        def path_for_routing_lookup(routing_lookup, params = {})
          path = case routing_lookup
          when Symbol
            route = @usher.named_routes[routing_lookup]
            raise UnrecognizedException unless route
            route.find_matching_path(params || {})
          when Route
            routing_lookup.find_matching_path(params)
          when nil
            params.is_a?(Hash) ? usher.path_for_options(params) : raise
          when Route::Path
            routing_lookup
          end
        end


        def generate_extra_params(params, has_question_mark)
          extra_params_result = ''

          params.each do |k,v|
            case v
            when Array
              v.each do |v_part|
                extra_params_result << (has_question_mark ? '&' : has_question_mark = true && '?') << Rack::Utils.escape("#{k.to_s}[]") << '=' << Rack::Utils.escape(v_part.to_s)
              end
            else
              extra_params_result << (has_question_mark ? '&' : has_question_mark = true && '?') << Rack::Utils.escape(k.to_s) << '=' << Rack::Utils.escape(v.to_s)
            end
          end
          extra_params_result
        end

      end

    end
  end
end

