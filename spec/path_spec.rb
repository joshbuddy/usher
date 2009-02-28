require 'lib/usher'

route_set = Usher.new

S = Usher::Route::Separator::Slash
D = Usher::Route::Separator::Dot

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
      [S, "a", S, "b"],
      [S, "a", S, "b", S, "c"],
      [S, "a", S, "b", S, "d"],
      [S, "a", S, "b", S, "d", S, "e"], 
      [S, "a", S, "b", S, "c", S, "d"], 
      [S, "a", S, "b", S, "c", S, "d", S, "e"]
    ]
    
  end

  it "should allow named routes to be added" do
    route_set.add_named_route(:route, '/bad/route', :controller => 'sample').should == route_set.named_routes[:route]
  end

end