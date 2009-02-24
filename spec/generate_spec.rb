require 'lib/compat'
require 'lib/usher'

route_set = Usher.new

describe "Usher URL generation" do
  
  before(:each) do
    route_set.reset!
  end
  
  it "should generate a simple URL" do
    route_set.add_named_route(:sample, '/sample', :controller => 'sample', :action => 'action')
    route_set.generate_url(:sample, {}).should == '/sample'
  end
  
  it "should generate a simple URL with a single variable" do
    route_set.add_named_route(:sample, '/sample/:action', :controller => 'sample')
    route_set.generate_url(:sample, {:action => 'action'}).should == '/sample/action'
  end
  
  it "should generate a simple URL with a single variable (thats not a string)" do
    route_set.add_named_route(:sample, '/sample/:action/:id', :controller => 'sample')
    route_set.generate_url(:sample, {:action => 'action', :id => 123}).should == '/sample/action/123'
  end
  
  it "should generate a simple URL with a glob variable" do
    route_set.add_named_route(:sample, '/sample/*action', :controller => 'sample')
    route_set.generate_url(:sample, {:action => ['foo', 'baz']}).should == '/sample/foo/baz'
  end
  
  it "should generate a mutliple vairable URL from a hash" do
    route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    route_set.generate_url(:sample, {:first => 'zoo', :second => 'maz'}).should == '/sample/zoo/maz'
  end

  it "should generate a mutliple vairable URL from an array" do
    route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    route_set.generate_url(:sample, ['maz', 'zoo']).should == '/sample/maz/zoo'
  end

  it "should generate append extra hash variables to the end" do
    route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    route_set.generate_url(:sample, {:first => 'maz', :second => 'zoo', :third => 'zanz'}).should == '/sample/maz/zoo?third=zanz'
  end

  it "should generate append extra hash variables to the end using [] syntax if its an array" do
    route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    route_set.generate_url(:sample, {:first => 'maz', :second => 'zoo', :third => ['zanz', 'susie']}).should == '/sample/maz/zoo?third%5B%5D=zanz&third%5B%5D=susie'
  end

  it "should generate a mutliple vairable URL from an array" do
    route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    route_set.generate_url(:sample, ['maz', 'zoo']).should == '/sample/maz/zoo'
  end

  it "should generate a simple URL with a format" do
    route_set.add_named_route(:sample, '/sample/:action.:format', :controller => 'sample')
    route_set.generate_url(:sample, {:action => 'action', :format => 'html'}).should == '/sample/action.html'
  end

end