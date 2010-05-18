# encoding: utf-8

require 'spec'
require 'spec/rake/spectask'
require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']   # optional
  t.options = ['--markup=markdown'] # optional
end

task :spec => ['spec:private', 'spec:rails2_2:spec', 'spec:rails2_3:spec']
namespace(:spec) do
  Spec::Rake::SpecTask.new(:private) do |t|
    t.spec_opts ||= []
    t.spec_opts << "-rubygems"
    t.spec_opts << "--options" << "spec/spec.opts"
    t.spec_files = FileList['spec/private/**/*_spec.rb']
  end

  namespace(:rails2_2) do
    task :unzip do
      sh('rm -rf spec/rails2_2/vendor')
      sh('unzip -qq spec/rails2_2/vendor.zip -dspec/rails2_2')
    end

    Spec::Rake::SpecTask.new(:only_spec) do |t|
      t.spec_opts ||= []
      t.spec_opts << "-rubygems"
      t.spec_opts << "--options" << "spec/spec.opts"
      t.spec_files = FileList['spec/rails2_2/**/*_spec.rb']
    end
    
    task :cleanup do
      sh('rm -rf spec/rails2_2/vendor')
    end

    task :spec => [:unzip, :only_spec, :cleanup]
  end

  namespace(:rails2_3) do
    task :unzip do
      sh('rm -rf spec/rails2_3/vendor')
      sh('unzip -qq spec/rails2_3/vendor.zip -dspec/rails2_3')
    end

    Spec::Rake::SpecTask.new(:only_spec) do |t|
      t.spec_opts ||= []
      t.spec_opts << "-rubygems"
      t.spec_opts << "--options" << "spec/spec.opts"
      t.spec_files = FileList['spec/rails2_3/**/*_spec.rb']
    end
    task :cleanup do
      sh('rm -rf spec/rails2_3/vendor')
    end

    task :spec => [:unzip, :only_spec, :cleanup]
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
