require 'merb-core'
require 'merb-core/dispatch/router/behavior'

class Usher
  module Interface
    class Merb
      
      # merb does everything with class methods.

      @root_behavior   = ::Merb::Router::Behavior.new.defaults(:action => "index")

      class << self
        attr_accessor :root_behavior
        
        UsherRoutes = Usher.new
        
        def prepare(first = [], last = [], &block)
          @routes = []
          root_behavior._with_proxy(&block)
          @routes = first + @routes + last
          compile
          self
        end
        
        def compile
          routes.each do |r| 
            r.segments
          end
          
          #puts r.inspect; UsherRoutes.add_route(r) }
          #routes.each {|r| }
        end
        
        def named_routes
          UsherRoutes.named_routes
        end
        
        def routes
          UsherRoutes.routes
        end

        def route_for(request)
          p request
          p UsherRoutes.tree
          UsherRoutes.recognize(request)
        end
        
      end
      
      #class BootLoader < ::Merb::BootLoader
      #end

      def load_into_merb!
        ::Merb.send(:remove_const, "Router")
        ::Merb.const_set("Router", Usher::Interface::MerbInterface)
        #::Merb::BootLoader.const_set("Router", Usher::Interface::Merb::BootLoader)
      end
      
    end
  end
end
