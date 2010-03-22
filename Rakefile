# encoding: utf-8

require 'spec'
require 'spec/rake/spectask'
task :spec => ['spec:private', 'spec:rails2_2', 'spec:rails2_3']
namespace(:spec) do
  Spec::Rake::SpecTask.new(:private) do |t|
    t.spec_opts ||= []
    t.spec_opts << "-rubygems"
    t.spec_opts << "--options" << "spec/spec.opts"
    t.spec_files = FileList['spec/private/**/*_spec.rb']
  end

  Spec::Rake::SpecTask.new(:rails2_2) do |t|
    t.spec_opts ||= []
    t.spec_opts << "-rubygems"
    t.spec_opts << "--options" << "spec/spec.opts"
    t.spec_files = FileList['spec/rails2_2/**/*_spec.rb']
  end

  Spec::Rake::SpecTask.new(:rails2_3) do |t|
    t.spec_opts ||= []
    t.spec_opts << "-rubygems"
    t.spec_opts << "--options" << "spec/spec.opts"
    t.spec_files = FileList['spec/rails2_3/**/*_spec.rb']
  end

end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('spec_with_rcov') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

require 'rake/rdoctask'
desc "Generate documentation"
Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = 'rdoc'
end

begin
  require 'code_stats'
  CodeStats::Tasks.new
rescue LoadError
end
