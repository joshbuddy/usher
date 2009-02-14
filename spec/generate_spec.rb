require 'lib/compat'
require 'lib/usher'

route_set = ActionController::Routing::UsherRoutes

describe "Usher URL generation" do
  
  it "should generate a simple URL" do
    route_set.add_named_route(:sample, '/sample', :controller => 'sample', :action => 'action')
    route_set.generate_url(:sample, {}).should == '/sample'
  end
  
  it "should generate a simple URL with a single variable" do
    route_set.add_named_route(:sample, '/sample/:action', :controller => 'sample')
    route_set.generate_url(:sample, {:action => 'action'}).should == '/sample/action'
  end
  
  it "should generate a simple URL with a glob variable" do
    route_set.add_named_route(:sample, '/sample/*action', :controller => 'sample')
    route_set.generate_url(:sample, {:action => ['foo', 'baz']}).should == '/sample/foo/baz'
  end
  
end