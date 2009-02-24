require 'lib/compat'
require 'lib/usher'

route_set = Usher.new

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
  
  
end