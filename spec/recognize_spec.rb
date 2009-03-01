require 'lib/usher'

route_set = Usher.new

def build_request(opts)
  request = mock "Request"
  opts.each do |k,v|
    request.should_receive(k).any_number_of_times.and_return(v)
  end
  request
end

SampleController = Object.new

describe "Usher route recognition" do
  
  before(:each) do
    route_set.reset!
  end
  
  it "should recognize a specific domain name" do
    target_route = route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http'})
    route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:protocol => 'https'})
    target_route.paths.include?(route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http'})).first).should == true
  end
  
  it "should recognize a specific route when several http-style restrictions are used" do
    target_route = route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http', :domain => 'admin.spec.com'})
    route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http', :domain => 'www.spec.com'})
    route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:protocol => 'https', :user_agent => 'MSIE 6.0'})
    route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:protocol => 'https', :domain => 'admin.spec.com'})
    target_route.paths.include?(route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http', :domain => 'admin.spec.com', :user_agent => nil})).first).should == true
  end
  
end