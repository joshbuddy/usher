require 'lib/usher'

route_set = Usher.new

describe "Usher route adding" do

  before(:each) do
    route_set.reset!
  end

  it "should be empty after a reset" do
    route_set.add_route('/sample', :controller => 'sample')
    route_set.empty?.should == false
    route_set.reset!
    route_set.empty?.should == true
  end
  
  it "shouldn't care about routes without a controller" do
    proc { route_set.add_route('/bad/route') }.should_not raise_error
  end

  it "should add every kind of optional route possible" do
    route_set.add_route('/a/b(/c)(/d(/e))')
    route_set.routes.first.paths.collect{|a| a.parts }.should == [
      ["a", "b"],
      ["a", "b", "c", "d"], 
      ["a", "b", "d", "e"], 
      ["a", "b", "c"],
      ["a", "b", "d"],
      ["a", "b", "c", "d", "e"]
    ]
    
  end

  it "should allow named routes to be added" do
    route_set.add_named_route(:route, '/bad/route', :controller => 'sample').should == route_set.named_routes[:route]
  end

end