# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{usher}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshua HullJoshua Hull"]
  s.date = %q{2009-03-01}
  s.email = %q{joshbuddy@gmail.comjoshbuddy@gmail.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "lib/compat.rb", "lib/usher.rb", "lib/usher/exceptions.rb", "lib/usher/grapher.rb", "lib/usher/interface.rb", "lib/usher/interface/merb_interface.rb", "lib/usher/interface/rack_interface.rb", "lib/usher/interface/rack_interface/mapper.rb", "lib/usher/interface/rack_interface/route.rb", "lib/usher/interface/rails2_interface.rb", "lib/usher/interface/rails2_interface/mapper.rb", "lib/usher/node.rb", "lib/usher/node/lookup.rb", "lib/usher/route.rb", "lib/usher/route/http.rb", "lib/usher/route/path.rb", "lib/usher/route/splitter.rb", "lib/usher/route/variable.rb", "rails/init.rb", "spec/generate_spec.rb", "spec/path_spec.rb", "spec/rack/dispatch_spec.rb", "spec/rails/generate_spec.rb", "spec/rails/path_spec.rb", "spec/rails/recognize_spec.rb", "spec/recognize_spec.rb", "spec/spec.opts", "spec/split_spec.rb", "usher.gemspec"]
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{usher}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Tree-based router}
  s.add_dependency(%q<fuzzy_hash>)

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.8.3"])
    else
      s.add_dependency(%q<hoe>, [">= 1.8.3"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.8.3"])
  end
end
