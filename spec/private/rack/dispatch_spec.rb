require 'lib/usher'
require 'rack'

route_set = Usher::Interface.for(:rack)

describe "Usher (for rack) route dispatching" do
  before(:each) do
    route_set.reset!
    @app = mock('app')
  end

  it "should dispatch a simple request" do
    @app.should_receive(:call).once.with { |v| v['usher.params'].should == {} }
    route_set.add('/sample').to(@app)
    route_set.call(Rack::MockRequest.env_for("/sample", :method => 'GET'))
  end
  
  it "should dispatch a POST request" do
    bad_app = mock('bad_app')
    @app.should_receive(:call).once.with { |v| v['usher.params'].should == {} }
    route_set.add('/sample').to(bad_app)
    route_set.add('/sample', :requirements => {:request_method => 'POST'}).to(@app)
    route_set.call(Rack::MockRequest.env_for("/sample", :request_method => 'POST'))
  end

  it "should returns HTTP 404 if route doesn't exist" do
    app = lambda { |env| "do nothing" }
    status, headers, body = route_set.call(Rack::MockRequest.env_for("/not-existing-url"))
    status.should eql(404)
  end
end
