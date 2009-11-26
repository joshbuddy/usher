if Rails::VERSION::MAJOR == 2 && Rails::VERSION::MINOR == 3
  ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails23)"
elsif Rails::VERSION::MAJOR == 2 && Rails::VERSION::MINOR >= 2
  class Usher::Interface::Rails2_2Interface::Mapper
    include ActionController::Resources
  end
  ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails22)"
end
