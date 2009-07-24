# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{usher}
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Joshua Hull"]
  s.date = %q{2009-07-24}
  s.description = %q{A general purpose routing library}
  s.email = %q{joshbuddy@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "History.txt",
     "Manifest.txt",
     "README.rdoc",
     "Rakefile",
     "VERSION.yml",
     "lib/usher.rb",
     "lib/usher/exceptions.rb",
     "lib/usher/grapher.rb",
     "lib/usher/interface.rb",
     "lib/usher/interface/email_interface.rb",
     "lib/usher/interface/merb_interface.rb",
     "lib/usher/interface/rack_interface.rb",
     "lib/usher/interface/rack_interface/mapper.rb",
     "lib/usher/interface/rack_interface/route.rb",
     "lib/usher/interface/rails2_2_interface.rb",
     "lib/usher/interface/rails2_2_interface/mapper.rb",
     "lib/usher/interface/rails2_3_interface.rb",
     "lib/usher/node.rb",
     "lib/usher/route.rb",
     "lib/usher/route/path.rb",
     "lib/usher/route/request_method.rb",
     "lib/usher/route/util.rb",
     "lib/usher/route/variable.rb",
     "lib/usher/splitter.rb",
     "lib/usher/util.rb",
     "lib/usher/util/generate.rb",
     "lib/usher/util/parser.rb",
     "rails/init.rb",
     "spec/private/email/recognize_spec.rb",
     "spec/private/generate_spec.rb",
     "spec/private/grapher_spec.rb",
     "spec/private/parser_spec.rb",
     "spec/private/path_spec.rb",
     "spec/private/rack/dispatch_spec.rb",
     "spec/private/rails2_2/compat.rb",
     "spec/private/rails2_2/generate_spec.rb",
     "spec/private/rails2_2/path_spec.rb",
     "spec/private/rails2_2/recognize_spec.rb",
     "spec/private/rails2_3/compat.rb",
     "spec/private/rails2_3/generate_spec.rb",
     "spec/private/rails2_3/path_spec.rb",
     "spec/private/rails2_3/recognize_spec.rb",
     "spec/private/recognize_spec.rb",
     "spec/private/request_method_spec.rb",
     "spec/spec.opts"
  ]
  s.homepage = %q{http://github.com/joshbuddy/usher}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{A general purpose routing library}
  s.test_files = [
    "spec/private/email/recognize_spec.rb",
     "spec/private/generate_spec.rb",
     "spec/private/grapher_spec.rb",
     "spec/private/parser_spec.rb",
     "spec/private/path_spec.rb",
     "spec/private/rack/dispatch_spec.rb",
     "spec/private/rails2_2/compat.rb",
     "spec/private/rails2_2/generate_spec.rb",
     "spec/private/rails2_2/path_spec.rb",
     "spec/private/rails2_2/recognize_spec.rb",
     "spec/private/rails2_3/compat.rb",
     "spec/private/rails2_3/generate_spec.rb",
     "spec/private/rails2_3/path_spec.rb",
     "spec/private/rails2_3/recognize_spec.rb",
     "spec/private/recognize_spec.rb",
     "spec/private/request_method_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<fuzzyhash>, [">= 0.0.5"])
    else
      s.add_dependency(%q<fuzzyhash>, [">= 0.0.5"])
    end
  else
    s.add_dependency(%q<fuzzyhash>, [">= 0.0.5"])
  end
end
