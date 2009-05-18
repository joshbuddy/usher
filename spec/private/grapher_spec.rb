require 'lib/usher'

route_set = Usher.new

describe "Usher grapher" do

  before(:each) do
    route_set.reset!
  end

  it "should find a simple path" do
    route_set.add_route('/:a/:b/:c')
    route_set.generate_url(nil, {:a => 'A', :b => 'B', :c => 'C'}).should == '/A/B/C'
  end

  it "should pick a more specific route" do
    route_set.add_route('/:a/:b')
    route_set.add_route('/:a/:b/:c')
    route_set.generate_url(nil, {:a => 'A', :b => 'B', :c => 'C'}).should == '/A/B/C'
  end

  it "should fail to generate a route when none matches" do
    route_set.add_route('/:a/:b')
    proc {route_set.generate_url(nil, {:c => 'C', :d => 'D'}) }.should raise_error Usher::UnrecognizedException
  end

  it "should find the most specific route and append extra parts on as a query string" do
    route_set.add_route('/:a/:b/:c')
    route_set.add_route('/:a/:b')
    route_set.generate_url(nil, {:a => 'A', :b => 'B', :d => 'C'}).should == '/A/B?d=C'
  end
  
  # FIXME
  #it "should do a validity check against the incoming variables when asked to" do
  #  route_set.add_route('/:a/:b', :b => /\d+/)
  #  route_set.generate_url(nil, {:a => 'A', :b => 'B'}).should == '/A/B'
  #  proc{ route_set.generate_url(nil, {:a => 'A', :b => 'B'})}.should raise_error Usher::ValidationException
  #end

end