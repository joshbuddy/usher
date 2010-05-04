class Usher
  module Interface
    class Sinatra

      def initialize
        ::Sinatra.send(:include, Extension)
      end

      module Extension

        def self.registered(app)
          app.send(:include, Extension)
        end

        def self.included(base)
          base.extend ClassMethods
        end

        def generate(name, *params)
          self.class.generate(name, *params)
        end

        private
          def route!(base=self.class, pass_block=nil)
            if base.router and match = base.router.recognize(@request, @request.path_info)
              if match.succeeded?
                @block_params = match.params.map { |p| p.last }
                (@params ||= {}).merge!(match.params_as_hash)
                pass_block = catch(:pass) do
                  route_eval(&match.destination)
                end
              elsif match.request_method?
                route_eval { 
                  response['Allow'] = match.acceptable_responses_only_strings.join(", ")
                  status 405
                }
                return
              end
            end

            # Run routes defined in superclass.
            if base.superclass.respond_to?(:router)
              route! base.superclass, pass_block
              return
            end

            route_eval(&pass_block) if pass_block

            route_missing
          end

        module ClassMethods

          def new(*args, &bk)
            configure! unless @_configured
            super(*args, &bk)
          end

          def route(verb, path, options={}, &block)
            path.gsub!(/\/\?$/, "(/)")
            name = options.delete(:name)
            options[:conditions] ||= {}
            options[:conditions][:request_method] = verb
            options[:conditions][:host] = options.delete(:host) if options.key?(:host)

            define_method "#{verb} #{path}", &block
            unbound_method = instance_method("#{verb} #{path}")
            block =
              if block.arity != 0
                lambda { unbound_method.bind(self).call(*@block_params) }
              else
                lambda { unbound_method.bind(self).call }
              end

            invoke_hook(:route_added, verb, path, block)

            route = router.add_route(path, options).to(block)
            route.name(name) if name
            route
          end

          def router
            @router ||= Usher.new(:request_methods => [:request_method, :host, :port, :scheme],
                                  :ignore_trailing_delimiters => true,
                                  :generator => Usher::Util::Generators::URL.new,
                                  :delimiters => ['/', '.', '-'],
                                  :valid_regex => '[0-9A-Za-z\$_\+!\*\',]+',
                                  :detailed_failure => true)
            block_given? ? yield(@router) : @router
          end

          def generate(name, *params)
            router.generator.generate(name, *params)
          end

          def reset!
            router.reset!
            super
          end

          def configure!
            configure :development do
              error 404 do
                content_type 'text/html'

                (<<-HTML).gsub(/^ {17}/, '')
                <!DOCTYPE html>
                <html>
                <head>
                  <style type="text/css">
                  body { text-align:center;font-family:helvetica,arial;font-size:22px;
                    color:#888;margin:20px}
                  #c {margin:0 auto;width:500px;text-align:left}
                  </style>
                </head>
                <body>
                  <h2>Sinatra doesn't know this ditty.</h2>
                  <div id="c">
                    Try this:
                    <pre>#{request.request_method.downcase} '#{request.path_info}' do\n  "Hello World"\nend</pre>
                  </div>
                </body>
                </html>
                HTML
              end
              error 405 do
                content_type 'text/html'

                (<<-HTML).gsub(/^ {17}/, '')
                <!DOCTYPE html>
                <html>
                <head>
                  <style type="text/css">
                  body { text-align:center;font-family:helvetica,arial;font-size:22px;
                    color:#888;margin:20px}
                  #c {margin:0 auto;width:500px;text-align:left}
                  </style>
                </head>
                <body>
                  <h2>Sinatra sorta knows this ditty, but the request method is not allowed.</h2>
                </body>
                </html>
                HTML
              end
            end

            @_configured = true
          end
        end # ClassMethods
      end # Extension
    end # Sinatra
  end # Interface
end # Usher