# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{usher}
  s.version = "0.3.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshua Hull"]
  s.date = %q{2009-04-27}
  s.description = %q{A general purpose routing library}
  s.email = %q{joshbuddy@gmail.com}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "Rakefile", "README.rdoc", "VERSION.yml", "lib/usher", "lib/usher/exceptions.rb", "lib/usher/grapher.rb", "lib/usher/interface", "lib/usher/interface/merb_interface.rb", "lib/usher/interface/rack_interface", "lib/usher/interface/rack_interface/mapper.rb", "lib/usher/interface/rack_interface/route.rb", "lib/usher/interface/rack_interface.rb", "lib/usher/interface/rails2_interface", "lib/usher/interface/rails2_interface/mapper.rb", "lib/usher/interface/rails2_interface.rb", "lib/usher/interface.rb", "lib/usher/node.rb", "lib/usher/route", "lib/usher/route/path.rb", "lib/usher/route/request_method.rb", "lib/usher/route/variable.rb", "lib/usher/route.rb", "lib/usher/splitter.rb", "lib/usher.rb", "spec/generate_spec.rb", "spec/grapher_spec.rb", "spec/path_spec.rb", "spec/rack", "spec/rack/dispatch_spec.rb", "spec/rails", "spec/rails/compat.rb", "spec/rails/generate_spec.rb", "spec/rails/path_spec.rb", "spec/rails/recognize_spec.rb", "spec/recognize_spec.rb", "spec/request_method_spec.rb", "spec/spec.opts", "spec/split_spec.rb", "rails/init.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/joshbuddy/usher}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A general purpose routing library}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<joshbuddy-fuzzy_hash>, [">= 0.0.3"])
    else
      s.add_dependency(%q<joshbuddy-fuzzy_hash>, [">= 0.0.3"])
    end
  else
    s.add_dependency(%q<joshbuddy-fuzzy_hash>, [">= 0.0.3"])
  end
end
