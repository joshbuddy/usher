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
  
  describe "mounted rack instances" do
    before do
      @bad_app = mock("bad_app")
      
      @usher2 = Usher::Interface.for(:rack)
      @usher2.add("/good" ).to(@app)
      @usher2.add("/bad"  ).match_partially!.to(@bad_app)
      @usher2.add("/some(/:foo)").to(@app)
      
      route_set.add("/foo/:bar", :default_values => {:foo => "foo"}).match_partially!.to(@usher2)
      route_set.add("/foo", :default_values => {:controller => :foo}).to(@app)
    end
    
    it "should match the route without nesting" do
      @app.should_receive(:call).once.with{ |e| e['usher.params'].should == {:controller => :foo}}
      route_set.call(Rack::MockRequest.env_for("/foo"))
    end
    
    it "should route through the first route, and the second to the app" do
      @app.should_receive(:call).once.with{|e| e['usher.params'].should == {:bar => "bar", :foo => "foo"}}
      result = route_set.call(Rack::MockRequest.env_for("/foo/bar/good"))
    end
    
    it "should go through to the bad app" do
      @bad_app.should_receive(:call).once.with{|e| e['usher.params'].should == {:bar => "some_bar", :foo => "foo"}}
      result = route_set.call(Rack::MockRequest.env_for("/foo/some_bar/bad"))
    end
    
    it "should match optional routes paramters" do
      @app.should_receive(:call).once.with{|e| e['usher.params'].should == {:bar => "bar", :foo => "a_different_foo"}}
      route_set.call(Rack::MockRequest.env_for("/foo/bar/some/a_different_foo"))
    end
  end
end
