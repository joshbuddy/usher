class Usher::Interface::Rails2::Mapper
  include ActionController::Resources
end
ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails2);"