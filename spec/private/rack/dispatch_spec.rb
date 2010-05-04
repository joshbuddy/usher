require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require "usher"
require 'rack'

route_set = Usher::Interface.for(:rack)
route_set.extend(CallWithMockRequestMixin)

describe "Usher (for rack) route dispatching" do
  before(:each) do
    @route_set = Usher::Interface.for(:rack, :redirect_on_trailing_delimiters => true)
    @route_set.extend(CallWithMockRequestMixin)
    @app = MockApp.new("Hello World!")
    @route_set.add('/sample').to(@app)
  end

  it "should dispatch a request" do
    response = @route_set.call_with_mock_request('/sample/')
    response.headers["Location"].should == "/sample"
  end

end

describe "Usher (for rack) route dispatching" do
  before(:each) do
    route_set.reset!
    @app = MockApp.new("Hello World!")
  end

  describe "HTTP GET" do
    before(:each) do
      route_set.reset!
      route_set.add('/sample', :conditions => {:request_method => 'GET'}).to(@app)
    end

    it "should dispatch a request" do
      response = route_set.call_with_mock_request
      response.body.should eql("Hello World!")
    end

    it "should write usher.params" do
      response = route_set.call_with_mock_request
      @app.env["usher.params"].should == {}
    end
  end

  describe "HTTP POST" do
    before(:each) do
      route_set.reset!
      route_set.add('/sample', :conditions => {:request_method => 'POST'}).to(@app)
      route_set.add('/sample').to(MockApp.new("You shouldn't get here if you are using POST"))
    end

    it "should dispatch a POST request" do
      response = route_set.call_with_mock_request('/sample', 'POST')
      response.body.should eql("Hello World!")
    end

    it "shouldn't dispatch a GET request" do
      response = route_set.call_with_mock_request('/sample', 'GET')
      response.body.should eql("You shouldn't get here if you are using POST")
    end

    it "should write usher.params" do
      response = route_set.call_with_mock_request("/sample", 'POST')
      @app.env["usher.params"].should == {}
    end
  end

  it "should returns HTTP 405 if the method mis-matches" do
    route_set.reset!
    route_set.add('/sample', :conditions => {:request_method => 'POST'}).to(@app)
    route_set.add('/sample', :conditions => {:request_method => 'PUT'}).to(@app)
    response = route_set.call_with_mock_request('/sample', 'GET')
    response.status.should eql(405)
    response['Allow'].should == 'POST, PUT'
  end

  it "should returns HTTP 404 if route doesn't exist" do
    response = route_set.call_with_mock_request("/not-existing-url")
    response.status.should eql(404)
  end

  describe "shortcuts" do
    describe "get" do
      before(:each) do
        route_set.reset!
        route_set.get('/sample').to(@app)
      end

      it "should dispatch a GET request" do
        response = route_set.call_with_mock_request("/sample", "GET")
        response.body.should eql("Hello World!")
      end

      it "should dispatch a HEAD request" do
        response = route_set.call_with_mock_request("/sample", "HEAD")
        response.body.should eql("Hello World!")
      end
    end
  end

  describe "non rack app destinations" do
    it "should route to a default application when using a hash" do
      $captures = []
      @default_app = lambda do |e|
        $captures << :default
        Rack::Response.new("Default").finish
      end
      @router = Usher::Interface.for(:rack)
      @router.default(@default_app)
      @router.add("/default").to(:action => "default")
      response = @router.call(Rack::MockRequest.env_for("/default"))
      $captures.should == [:default]
    end
  end

  describe "mounted rack instances" do
    before do
      @bad_app = mock("bad_app")

      @usher2 = Usher::Interface.for(:rack)
      @usher2.add("/good" ).to(@app)
      @usher2.add("/bad"  ).match_partially!.to(@bad_app)
      @usher2.add("/some(/:foo)").to(@app)

      @usher3 = Usher::Interface.for(:rack)
      @usher3.add("(/)", :default_values => {:optional_root => true} ).to(@app)

      @usher2.add("/optional_mount").match_partially!.to(@usher3)

      route_set.add("/baz", :default_values => {:baz => "baz"}).match_partially!.to(@usher3)
      route_set.add("/foo/:bar", :default_values => {:foo => "foo"}).match_partially!.to(@usher2)
      route_set.add("/foo", :default_values => {:controller => :foo}).to(@app)
    end

    it "should match the route without nesting" do
      @app.should_receive(:call).once.with{ |e| e['usher.params'].should == {:controller => :foo}}
      route_set.call(Rack::MockRequest.env_for("/foo"))
    end

    it "should match the route where the last part is optional" do
      @app.should_receive(:call).once.with do |e|
        e['usher.params'].should == {
          :optional_root  => true,
          :baz            => 'baz'
        }
      end
      route_set.call(Rack::MockRequest.env_for("/baz/"))
    end

    it "should match when a mounted apps root route is optional" do
      @app.should_receive(:call).once.with do |e|
        e['usher.params'].should == {
          :optional_root => true,
          :foo           => "foo",
          :bar           => "bar"
        }
      end
      route_set.call(Rack::MockRequest.env_for("/foo/bar/optional_mount"))
    end

    it "should match the route where the last part is empty" do
      @app.should_receive(:call).once.with do |e|
        e['usher.params'].should == {
          :baz            => 'baz',
          :optional_root  => true
        }
      end
      route_set.call(Rack::MockRequest.env_for("/baz"))
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

    describe "SCRIPT_NAME & PATH_INFO" do
      it "shouldn't update the script name for a fully consumed route" do
        @app.should_receive(:call).once.with do |e|
          e['SCRIPT_NAME'].should == ""
          e['PATH_INFO'].should   == "/foo"
        end
        route_set.call(Rack::MockRequest.env_for("/foo"))
      end

      it "should update the script name and path info for a partially consumed route" do
        @app.should_receive(:call).once.with do |e|
          e['SCRIPT_NAME'].should == "/partial"
          e['PATH_INFO'].should   == "/bar/baz"
        end

        route_set.add("/partial").match_partially!.to(@app)
        route_set.call(Rack::MockRequest.env_for("/partial/bar/baz"))
      end

      it "should consume the path through a mounted usher" do
        @bad_app.should_receive(:call).once.with do |e|
          e['SCRIPT_NAME'].should == "/foo/bar/bad"
          e['PATH_INFO'].should   == "/leftovers"
        end

        route_set.call(Rack::MockRequest.env_for("/foo/bar/bad/leftovers"))
      end

      it "should not modify SCRIPT_NAME in place since thin freezes it" do
        @app.should_receive(:call).once
        env = Rack::MockRequest.env_for("/foo/bar/good")
        env["SCRIPT_NAME"] = "".freeze
        route_set.call(env)
      end
    end

    describe "dupping" do
      before do
        @app  = mock("app")
        @u1   = Usher::Interface.for(:rack)
        @u2   = Usher::Interface.for(:rack)

        @u1.add("/one", :default_values => {:one => :one}).to(@app)
        @u1.add("/mount").match_partially!.to(@u2)

        @u2.add("/app", :default_values => {:foo => :bar}).to(@app)

      end

      it "should allow me to dup the router" do
        @app.should_receive(:call).twice.with{|e| e['usher.params'].should == {:one => :one}}
        @u1.call(Rack::MockRequest.env_for("/one"))
        u1_dash = @u1.dup
        u1_dash.call(Rack::MockRequest.env_for("/one"))
      end

      it "should allow me to dup the router and add a new route without polluting the original" do
        @app.should_receive(:call).with{|e| e['usher.params'].should == {:foo => :bar}}
        u1_dash = @u1.dup
        u1_dash.add("/foo", :default_values => {:foo => :bar}).to(@app)
        u1_dash.call(Rack::MockRequest.env_for("/foo"))
        @app.should_not_receive(:call)
        @u1.call(Rack::MockRequest.env_for("/foo"))
      end

      it "should allow me to dup the router and nested routers should remain intact" do
        @app.should_receive(:call).with{|e| e['usher.params'].should == {:foo => :bar}}
        u1_dash = @u1.dup
        u1_dash.call(Rack::MockRequest.env_for("/mount/app"))
      end

      it "should allow me to dup the router and add more routes" do
        @app.should_receive(:call).with{|e| e['usher.params'].should == {:another => :bar}}

        u3 = Usher::Interface.for(:rack)
        u1_dash = @u1.dup

        u3.add("/another_bar", :default_values => {:another => :bar}).to(@app)
        u1_dash.add("/some/mount").match_partially!.to(u3)

        u1_dash.call(Rack::MockRequest.env_for("/some/mount/another_bar"))

        @app.should_not_receive(:call)
        @u1.call(Rack::MockRequest.env_for("/some/mount/another_bar"))
      end
    end
  end

  describe "use as middlware" do
    it "should allow me to set a default application to use" do
      @app.should_receive(:call).with{|e| e['usher.params'].should == {:middle => :ware}}

      u = Usher::Interface.for(:rack)
      u.default @app
      u.add("/foo", :default_values => {:middle => :ware}).name(:foo)

      u.call(Rack::MockRequest.env_for("/foo"))
    end

    it "should use the default application when no routes match" do
      env = Rack::MockRequest.env_for("/not_a_route")
      @app.should_receive(:call).with(env)
      u = Usher::Interface.for(:rack)
      u.default @app
      u.call(env)
    end

    it "should allow me to set the application after initialization" do
      @app.should_receive(:call).with{|e| e['usher.params'].should == {:after => :stuff}}
      u = Usher::Interface.for(:rack)
      u.default @app
      u.add("/foo", :default_values => {:after => :stuff})
      u.call(Rack::MockRequest.env_for("/foo"))
    end
  end
end
