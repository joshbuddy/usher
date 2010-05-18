class Usher
  module Util
    class Rails
      
      def self.activate
        rails_version = "#{::Rails::VERSION::MAJOR}.#{::Rails::VERSION::MINOR}"

        case rails_version
        when '2.3'
          ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails23)"

        when '2.2'
          Usher::Interface::Rails22::Mapper.module_eval("include ActionController::Resources")
          ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails22)"

        when '2.0'
          Usher::Interface::Rails20::Mapper.module_eval("include ActionController::Resources")
          ActionController::Routing.module_eval <<-CODE
            remove_const(:Routes);
            interface = Usher::Interface.for(:rails20);
            interface.configuration_file = File.join(RAILS_ROOT, 'config', 'routes.rb')
            Routes = interface;
          CODE
        when '3.0'
          ActionController::Routing.module_eval <<-CODE
            remove_const(:Routes);
            interface = Usher::Interface.for(:rails20);
            interface.configuration_file = File.join(RAILS_ROOT, 'config', 'routes.rb')
            Routes = interface;
          CODE
        end
      end
      
    end
  end
end