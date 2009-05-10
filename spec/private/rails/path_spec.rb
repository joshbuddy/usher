require File.join(File.dirname(__FILE__), 'compat')
require 'lib/usher'

route_set = Usher::Interface.for(:rails2)

describe "Usher (for rails) route adding" do

  before(:each) do
    route_set.reset!
  end

  it "shouldn't allow routes without a controller to be added" do
    proc { route_set.add_route('/bad/route') }.should raise_error
  end

end