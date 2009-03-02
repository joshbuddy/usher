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
  
  it "should recognize a regex domain name" do
    target_route = route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:domain => /^admin.*$/})
    route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:domain => 'www.host.com'})
    target_route.paths.include?(route_set.recognize(build_request({:method => 'get', :path => '/sample', :domain => 'admin.host.com'})).first).should == true
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
  
  it "should correctly fix that tree if conditionals are used later" do
    noop_route = route_set.add_route('noop', :controller => 'products', :action => 'noop')
    product_show_route = route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:method => 'get'})
    noop_route.paths.include?(route_set.recognize(build_request({:method => 'get', :path => '/noop', :domain => 'admin.host.com'})).first).should == true
    product_show_route.paths.include?(route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :domain => 'admin.host.com'})).first).should == true
  end
  
  it "should should raise if malformed variables are used" do
    route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:method => 'get'})
    proc {route_set.recognize(build_request({:method => 'get', :path => '/products/show/qweasd', :domain => 'admin.host.com'}))}.should raise_error
  end
  
end