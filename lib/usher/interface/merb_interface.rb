$:.unshift File.dirname(__FILE__)

require 'merb-core'
require 'merb-core/dispatch/router/behavior'

class Usher
  module Interface
    class MerbInterface
      
      # merb does everything with class methods.

      @root_behavior   = ::Merb::Router::Behavior.new.defaults(:action => "index")

      class << self
        attr_accessor :root_behavior
        
        UsherRoutes = Usher.new
        
        def prepare(first = [], last = [], &block)
          routes = []
          root_behavior._with_proxy(&block)
          routes = first + routes + last
          routes.each {|r| UsherRoutes.add_route(r) }
          self
        end
        
        def named_routes
          UsherRoutes.named_routes
        end
        
        def routes
          UsherRoutes.routes
        end

        def route_for(request)
          (route, params) = UsherRoutes.recognize(request)
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
