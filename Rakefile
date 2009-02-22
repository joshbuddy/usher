require 'hoe'
require 'spec'
require 'spec/rake/spectask'
require 'lib/usher'

Hoe.new('usher', Usher::Version) do |p|
  p.author = 'Joshua Hull'
  p.email = 'joshbuddy@gmail.com'
  p.summary = 'Tree-based router'
end

task :spec => 'spec:all'
namespace(:spec) do
  task :all => [:usher]

  Spec::Rake::SpecTask.new(:usher) do |t|
    t.spec_opts ||= []
    t.spec_opts << "-rubygems"
    t.spec_opts << "--options" << "spec/spec.opts"
    t.spec_files = FileList['spec/**/*_spec.rb']
  end

end

