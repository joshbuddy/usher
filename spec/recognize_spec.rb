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
    target_route_http_admin = route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http', :domain => 'admin.spec.com'})
    target_route_http_www = route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http', :domain => 'www.spec.com'})
    target_route_https_msie = route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:protocol => 'https', :user_agent => 'MSIE 6.0'})
    target_route_https_admin = route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:protocol => 'https', :domain => 'admin.spec.com'})
    target_route_http_admin.paths.include?(route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http', :domain => 'admin.spec.com', :user_agent => nil})).first).should == true
    target_route_http_www.paths.include?(route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http', :domain => 'www.spec.com', :user_agent => nil})).first).should == true
    target_route_https_msie.paths.include?(route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'https', :domain => 'admin.spec.com', :user_agent => 'MSIE 6.0'})).first).should == true
    target_route_https_admin.paths.include?(route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'https', :domain => 'admin.spec.com', :user_agent => nil})).first).should == true
  end
  
end