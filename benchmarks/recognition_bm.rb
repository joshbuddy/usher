require 'rubygems'
require 'rbench'
require 'lib/usher'

u = Usher.new(:generator => Usher::Util::Generators::URL.new)
u.add_route('/simple').name(:simple)

TIMES = 100_00

RBench.run(TIMES) do
  
  report "simple" do
    u.recognize_path('/simple')
  end
  
end