# -*- encoding: utf-8 -*-
require 'lib/usher'

Gem::Specification.new do |s|
  s.name = %q{usher}
  s.version = Usher::Version

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshua Hull"]
  s.date = %q{2009-02-22}
  s.description = %q{}
  s.email = %q{joshbuddy@gmail.com}
  s.extra_rdoc_files = ["Manifest.txt", "README.txt"]
  s.files = ["lib", "lib/compat.rb", "lib/usher", "lib/usher/grapher.rb", "lib/usher/interface", "lib/usher/interface/rails2", "lib/usher/interface/rails2/mapper.rb", "lib/usher/interface/rails2.rb", "lib/usher/interface.rb", "lib/usher/node.rb", "lib/usher/route.rb", "lib/usher.rb", "Manifest.txt", "rails", "rails/init.rb", "Rakefile", "README.rdoc", "README.txt", "spec", "spec/rails", "spec/rails/generate_spec.rb", "spec/rails/path_spec.rb", "spec/rails/recognize_spec.rb", "spec/spec.opts"]
  s.has_rdoc = true
  s.homepage = %q{Tree-based router for Ruby on Rails.}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{usher}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Tree-based router}

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
