require File.expand_path(File.join(File.dirname(__FILE__), 'compat'))
require "usher"

route_set = Usher::Interface.for(:rails22)

describe "Usher (for rails 2.2) route adding" do

  before(:each) do
    route_set.reset!
  end

  it "shouldn't allow routes without a controller to be added" do
    proc { route_set.add_route('/bad/route') }.should raise_error
  end

end
