require 'lib/compat'
require 'lib/usher'

route_set = Usher::Interface.for(:rails2)

describe "Usher (for rails) URL generation" do
  
  before(:each) do
    route_set.reset!
  end

  it "should fill in the controller from recall" do
    route_set.add_route(':controller/:action/:id')
    route_set.generate({:action => 'thingy'}, {:controller => 'sample', :action => 'index', :id => 123}, :generate).should == '/sample/thingy'
  end

end