class Usher
  module Interface
    class Sinatra
      
      module Extension
        
        def self.included(cls)
          cls::Base.class_eval(<<-HERE_DOC, __FILE__, __LINE__)
            def self.route(verb, path, options={}, &block)
              @router ||= Usher.new(:request_methods => [:request_method, :host, :port, :scheme], :generator => Usher::Util::Generators::URL.new)

              name = options.delete(:name)
              options[:conditions] ||= {}
              options[:conditions][:request_method] = verb
              options[:conditions][:host] = options.delete(:host) if options.key?(:host)

              # Because of self.options.host
              host_name(options.delete(:host)) if options.key?(:host)

              define_method "\#{verb} \#{path}", &block
              unbound_method = instance_method("\#{verb} \#{path}")
              block =
                if block.arity != 0
                  lambda { unbound_method.bind(self).call(*@block_params) }
                else
                  lambda { unbound_method.bind(self).call }
                end

              invoke_hook(:route_added, verb, path, block)

              route = @router.add_route(path, options).to(block)
              route.name(name) if name
              route
            end          

            def self.router
              @router
            end

            def route!(base = self.class)
              if match = self.class.router.recognize(@request)
                @params = @params ? @params.merge(match.params_as_hash) : match.params_as_hash
                route_eval(&match.destination)
              elsif base.superclass.respond_to?(:routes)
                route! base.superclass
              else
                route_missing
              end
            end
            
            def generate(name, *params)
              self.class.router.generator.generate(name, *params)
            end

          HERE_DOC
        end
        
      end
      
      def initialize
        ::Sinatra.send(:include, Extension)
      end
    end
  end
end