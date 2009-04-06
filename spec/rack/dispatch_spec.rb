require 'lib/usher'

route_set = Usher::Interface.for(:rack)

def build_request_mock(path, method, params)
  request = mock "Request"
  request.should_receive(:path).any_number_of_times.and_return(path)
  request.should_receive(:method).any_number_of_times.and_return(method)
  params = params.with_indifferent_access
  request.should_receive(:path_parameters=).any_number_of_times.with(params)
  request.should_receive(:path_parameters).any_number_of_times.and_return(params)
  request
end

def build_app_mock(params)
  request = mock "App"
  request.should_receive(:call).any_number_of_times.with(params)
  request
end

SampleController = Object.new

describe "Usher (for rack) route dispatching" do

  before(:each) do
    route_set.reset!
  end

  it "should dispatch a simple request" do
    env = {'REQUEST_URI' => '/sample', 'REQUEST_METHOD' => 'get', 'usher.params' => {}}
    route_set.add('/sample').to(build_app_mock(env.dup))
    route_set.call(env)
  end
  
end