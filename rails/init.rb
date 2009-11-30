rails_version = "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"

case rails_version
  when '2.3'
    ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails23)"

  when '2.2'
    class Usher::Interface::Rails22::Mapper
      include ActionController::Resources
    end
    ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails22)"

  when '2.0'
    class Usher::Interface::Rails20::Mapper
      include ActionController::Resources
    end

    ActionController::Routing.module_eval <<CODE
      remove_const(:Routes);
      interface = Usher::Interface.for(:rails20);
      interface.configuration_file = File.join(RAILS_ROOT, 'config', 'routes.rb')
      Routes = interface;
CODE
end