require 'lib/usher'

require 'rack'

route_set = Usher::Interface.for(:rack)

describe "Usher (for rack) route dispatching" do

  before(:each) do
    route_set.reset!
  end

  it "should dispatch a simple request" do
    app = mock 'app'
    app.should_receive(:call).once.with {|v| v['usher.params'].should == {} }
    route_set.add('/sample').to(app)
    route_set.call(Rack::MockRequest.env_for("/sample", :method => 'GET'))
  end
  
  it "should dispatch a POST request" do
    bad_app = mock 'bad_app'
    app = mock 'app'
    app.should_receive(:call).once.with {|v| v['usher.params'].should == {} }
    route_set.add('/sample').to(bad_app)
    route_set.add('/sample', :requirements => {:request_method => 'POST'}).to(app)
    route_set.call(Rack::MockRequest.env_for("/sample", :request_method => 'POST'))
  end
  
end
