require 'lib/usher'
require 'rack'

require File.join(File.dirname(__FILE__), "..", "..", "spec_helper")
route_set = Usher::Interface.for(:rack)
route_set.extend(CallWithMockRequestMixin)

describe "Usher (for rack) route generation" do
  before(:each) do
    route_set.reset!
    @app = MockApp.new("Hello World!")
    route_set.add("/fixed").name(:fixed)
    route_set.add("/simple/:simple_var")
    route_set.add("/named/simple/:named_simple_var").name(:simple)
    route_set.add("/optional(/:optional_var)")
    route_set.add("/named/optional(/:named_optional_var)").name(:optional)
  end
  
  describe "named routes" do
    it "should generate a fixed path" do
      route_set.generate(:fixed).should == "/fixed"
    end
    
    it "should generate a basic path route" do
      route_set.generate(nil, :simple_var => "simple_var").should == "/simple/simple_var"
    end

    it "should generate a named path route" do
      route_set.generate(:simple, :named_simple_var => "the_var").should == "/named/simple/the_var"
    end

    it "should generate a route with options" do
      route_set.generate(nil, :optional_var => "var").should == "/optional/var"
    end

    it "should generate a named route with options" do
      route_set.generate(:optional).should == "/named/optional"
      route_set.generate(:optional, :named_optional_var => "the_var").should == "/named/optional/the_var"
    end
  end
end
