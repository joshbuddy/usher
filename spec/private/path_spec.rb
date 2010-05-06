require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "usher"

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
      ["/", "a", "/", "b"],
      ["/", "a", "/", "b", "/", "c"],
      ["/", "a", "/", "b", "/", "d"],
      ["/", "a", "/", "b", "/", "c", "/", "d"],
      ["/", "a", "/", "b", "/", "d", "/", "e"],
      ["/", "a", "/", "b", "/", "c", "/", "d", "/", "e"]
    ]
  end

  it "should allow named routes to be added" do
    route_set.add_named_route(:route, '/bad/route', :controller => 'sample').should == route_set.named_routes[:route]
  end

  it "should allow named routes to be deleted" do
    route_set.add_named_route(:route, '/bad/route', :controller => 'sample').should == route_set.named_routes[:route]
    route_set.route_count.should == 1
    route_set.named_routes.size == 1
    route_set.delete_named_route(:route, '/bad/route', :controller => 'sample')
    route_set.route_count.should == 0
    route_set.named_routes.size == 0
  end

  describe "merging paths" do
    before do
      @r1 = route_set.add_route("/foo/bar")
      @r2 = route_set.add_route("/other(/:baz)")
      @p1 = @r1.paths.first
      @p2 = @r2.paths.first
    end
    
    it "should craete a new path object" do
      @p1.merge(@p2).should_not eql(@p1)
    end
    
    it "should mash the parts together" do
      @p1.merge(@p2).parts.should == (@p1.parts + @p2.parts).flatten
    end
    
    it "should maintain the route owner" do
      @p1.merge(@p2).route.should == @p1.route
    end
    
  end

end
