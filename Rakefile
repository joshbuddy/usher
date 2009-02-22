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
  Spec::Rake::SpecTask.new(:all) do |t|
    t.spec_opts ||= []
    t.spec_opts << "-rubygems"
    t.spec_opts << "--options" << "spec/spec.opts"
    t.spec_files = FileList['spec/**/*_spec.rb']
  end

end

task :cultivate do
  system "touch Manifest.txt; rake check_manifest | grep -v \"(in \" | patch"
  system "rake debug_gem | grep -v \"(in \" > `basename \\`pwd\\``.gemspec"
end