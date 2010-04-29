require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require "usher"
require "sinatra"

describe "Usher (for Sinatra) route recognition" do
  before(:each) do
    @app = Sinatra.new { register Usher::Interface::Sinatra::Extension }
    @app.extend(CallWithMockRequestMixin)
    @app.reset!
  end

  describe "basic functionality" do
    it "should map not found" do
      response = @app.call_with_mock_request('/bar')
      response.status.should == 404
    end

    it "should map index" do
      @app.get("/") { "index" }
      response = @app.call_with_mock_request('/')
      response.status.should == 200
      response.body.should == "index"
    end

    it "should ignore trailing delimiters" do
      @app.get("/foo") { "foo" }
      response = @app.call_with_mock_request('/foo')
      response.status.should == 200
      response.body.should == "foo"
      response = @app.call_with_mock_request('/foo/')
      response.status.should == 200
      response.body.should == "foo"
    end

    it "should ignore trailing delimiters in a more advanced route" do
      @app.get("/foo") { "foo" }
      @app.get("/foo/bar") { "bar" }
      response = @app.call_with_mock_request('/foo')
      response.status.should == 200
      response.body.should == "foo"
      response = @app.call_with_mock_request('/foo/bar')
      response.status.should == 200
      response.body.should == "bar"
      response = @app.call_with_mock_request('/foo/')
      response.status.should == 200
      response.body.should == "foo"
      response = @app.call_with_mock_request('/foo/bar/')
      response.status.should == 200
      response.body.should == "bar"
    end

    it "should use sinatra optionals trailing delimiters" do
      @app.get("/foo/?") { "foo" }
      response = @app.call_with_mock_request('/foo')
      response.status.should == 200
      response.body.should == "foo"
      response = @app.call_with_mock_request('/foo/')
      response.status.should == 200
      response.body.should == "foo"
    end
  end

  describe "mapping functionality" do

    it "should map a basic route" do
      @app.get('/hi', :name => :hi) { generate(:hi) } 
      response = @app.call_with_mock_request('/hi')
      response.status.should == 200
      response.body.should == "/hi"
    end

    it "should map a basic route ignoring trailing delimiters" do
      @app.get('/hi', :name => :hi) { generate(:hi) } 
      response = @app.call_with_mock_request('/hi/')
      response.status.should == 200
      response.body.should == "/hi"
    end

    it "should map a basic route with params" do
      @app.get('/hi/:id', :name => :hi) { generate(:hi, :id => 18) } 
      response = @app.call_with_mock_request('/hi/1')
      response.status.should == 200
      response.body.should == "/hi/18"
    end

    it "should map route with params" do
      @app.get('/hi-:id', :name => :hi) { generate(:hi, :id => 18) } 
      response = @app.call_with_mock_request('/hi-1')
      response.status.should == 200
      response.body.should == "/hi-18"
    end
  end

  describe "not found" do

    it "should correctly generate a not found page without images" do
      response = @app.call_with_mock_request('/bar')
      response.status.should == 404
      response.body.should_not match(/__sinatra__/)
    end
  end
end