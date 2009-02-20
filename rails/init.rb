class Usher::Mapper
  include ActionController::Resources
end
ActionController::Routing.module_eval "remove_const(:Routes); Routes = Usher.new;"