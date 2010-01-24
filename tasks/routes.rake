desc 'Print out all defined routes in match order, with names.'

# borrowed from eugenebolshakov / override_rake_task, wish this was a gem!
Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end
 
def remove_task(task_name)
  Rake.application.remove_task(task_name)
end
 
def override_task(args, &block)
  name, deps = Rake.application.resolve_args([args])  
  remove_task Rake.application[name].name
  task(args, &block)
end

override_task :routes => :environment do
  routes = ActionController::Routing::Routes.routes.collect do |route|
    name = route.named.to_s
    verb = route.conditions && route.conditions[:method].to_s.upcase || ''
    path = route.original_path
    reqs = route.requirements.blank? ? "" : route.requirements.inspect
    dests = route.destination.inspect
    {:name => name, :verb => verb, :path => path, :reqs => reqs, :dests => dests}
  end

  name_width = routes.collect {|r| r[:name]}.collect {|n| n.length}.max
  verb_width = routes.collect {|r| r[:verb]}.collect {|v| v.length}.max
  path_width = routes.collect {|r| r[:path]}.collect {|s| s.length}.max
  dests_width = routes.collect {|r| r[:dests]}.collect {|s| s.length}.max
  routes.each do |r|
    puts "#{r[:name].rjust(name_width)} #{r[:verb].ljust(verb_width)} #{r[:path].ljust(path_width)} #{r[:reqs]}  #{r[:dests]}"
  end
end
