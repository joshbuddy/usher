class Usher::Interface::Rails2Interface::Mapper
  include ActionController::Resources
end
ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher::Interface.for(:rails2);"