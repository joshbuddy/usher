require 'lib/compat'
require 'lib/usher'

route_set = ActionController::Routing::UsherRoutes

def build_request_mock(path, method, params)
  request = mock "Request"
  request.should_receive(:path).any_number_of_times.and_return(path)
  request.should_receive(:method).any_number_of_times.and_return(method)
  params = params.with_indifferent_access
  request.should_receive(:path_parameters=).any_number_of_times.with(params)
  request.should_receive(:path_parameters).any_number_of_times.and_return(params)
  request
end

SampleController = Object.new

describe "Usher route recognition" do

  before(:each) do
    route_set.reset!
  end

  it "should recognize a simple request" do
    route_set.add_route('/sample', :controller => 'sample', :action => 'action')
    route_set.recognize(build_request_mock('/sample', 'get', {:controller => 'sample', :action => 'action'})).should == SampleController
  end

  it "should interpolate action :index" do
    route_set.add_route('/sample', :controller => 'sample')
    route_set.recognize(build_request_mock('/sample', 'get', {:controller => 'sample', :action => 'index'})).should == SampleController
  end

  it "should correctly distinguish between multiple request methods" do
    route_set.add_route('/sample', :controller => 'not_sample', :conditions => {:method => :get})
    correct_route = route_set.add_route('/sample', :controller => 'sample', :conditions => {:method => :post})
    route_set.add_route('/sample', :controller => 'not_sample', :conditions => {:method => :put})
    route_set.recognize(build_request_mock('/sample', :post, {:controller => 'sample', :action => 'index'})).should == SampleController
  end

  it "should prefer the static route to the dynamic route" do
    route_set.add_route('/sample/:action', :controller => 'not_sample')
    route_set.add_route('/sample/test', :controller => 'sample', :action => 'action')
    route_set.recognize(build_request_mock('/sample/test', 'get', {:controller => 'sample', :action => 'action'})).should == SampleController
  end
  
  it "should raise based upon an invalid param" do
    route_set.add_named_route(:sample, '/sample/:action', :controller => 'sample', :requirements => {:action => /\d+/})
    proc { route_set.recognize(build_request_mock('/sample/asdqwe', :post, {})) }.should raise_error
  end
  
end