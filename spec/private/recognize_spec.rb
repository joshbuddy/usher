require 'lib/usher'

route_set = Usher.new

def build_request(opts)
  request = mock "Request"
  opts.each do |k,v|
    request.should_receive(k).any_number_of_times.and_return(v)
  end
  request
end

describe "Usher route recognition" do
  
  before(:each) do
    route_set.reset!
  end
  
  it "should recognize a specific domain name" do
    target_route = route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http'})
    route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:protocol => 'https'})
    route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http'})).path.route.should == target_route
  end
  
  it "should recognize a regex domain name" do
    target_route = route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:domain => /^admin.*$/})
    route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:domain => 'www.host.com'})
    route_set.recognize(build_request({:method => 'get', :path => '/sample', :domain => 'admin.host.com'})).path.route.should == target_route
  end
  
  it "should recognize a format-style variable" do
    target_route = route_set.add_route('/sample.:format', :controller => 'sample', :action => 'action')
    route_set.recognize(build_request({:method => 'get', :path => '/sample.html', :domain => 'admin.host.com'})).should == Usher::Node::Response.new(target_route.paths.first, [[:format , 'html']])
  end
  
  it "should recognize a glob-style variable" do
    target_route = route_set.add_route('/sample/*format', :controller => 'sample', :action => 'action')
    route_set.recognize(build_request({:method => 'get', :path => '/sample/html/json/apple'})).params.should == [[:format, ['html', 'json', 'apple']]]
  end
  
  it "should recgonize only a glob-style variable" do
    target_route = route_set.add_route('/*format')
    response = route_set.recognize(build_request({:method => 'get', :path => '/sample/html/json/apple'}))
    response.params.should == [[:format, ['sample', 'html', 'json', 'apple']]]
    response.path.route.should == target_route
  end
  
  it "should recgonize a regex static part" do
    target_route = route_set.add_route('/test/part/{one|two}')
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/one'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/two'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/three'})).should == nil
  end
  
  it "shouldn't accept a nil variable" do
    target_route = route_set.add_route('/:one')
    route_set.recognize(build_request({:method => 'get', :path => '/one'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/'})).should == nil
  end
  
  it "should recgonize a regex static part containing {}'s" do
    target_route = route_set.add_route('/test/part/{^o{2,3}$}')
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/oo'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/ooo'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/oooo'})).should == nil
  end
  
  it "should recgonize a regex single variable" do
    target_route = route_set.add_route('/test/part/{:test,hello|again}')
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello'})).params.should == [[:test, 'hello']]
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/again'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/again'})).params.should == [[:test, 'again']]
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/world'})).should == nil
  end
  
  it "should recgonize a regex glob variable" do
    target_route = route_set.add_route('/test/part/{*test,^(hello|again|\d+)$}')
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again'})).params.should == [[:test, ['hello', 'again', '123', 'hello', 'again']]]
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/agaim/123/hello/again'})).should == nil
  end
  
  it "should recgonize a regex glob variable terminated by a static part" do
    target_route = route_set.add_route('/test/part/{*test,^(hello|again|\d+)$}/onemore')
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again/onemore'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again/onemore'})).params.should == [[:test, ['hello', 'again', '123', 'hello', 'again']]]
  end
  
  it "should recgonize a regex glob variable terminated by a single regex variable" do
    target_route = route_set.add_route('/test/part/{*test,^(hello|again|\d+)$}/{:party,onemore}')
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again/onemore'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again/onemore'})).params.should == [[:test, ['hello', 'again', '123', 'hello', 'again']], [:party, 'onemore']]
  end

  it "should recgonize a greedy regex single variable" do
    target_route = route_set.add_route('/test/part/{!test,one/more/time}')
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/one/more/time'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/one/more/time'})).params.should == [[:test, 'one/more/time']]
  end

  it "should recgonize a greedy regex single variable with static parts after" do
    target_route = route_set.add_route('/test/part/{!test,one/more/time}/help')
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/one/more/time/help'})).path.route.should == target_route
    route_set.recognize(build_request({:method => 'get', :path => '/test/part/one/more/time/help'})).params.should == [[:test, 'one/more/time']]
  end

  it "should recgonize two glob-style variables separated by a static part" do
    target_route = route_set.add_route('/*format/innovate/*onemore')
    response = route_set.recognize(build_request({:method => 'get', :path => '/sample/html/innovate/apple'}))
    response.params.should == [[:format, ['sample', 'html']], [:onemore, ['apple']]]
    response.path.route.should == target_route
  end
  
  it "should recgonize only a glob-style variable with a condition" do
    target_route = route_set.add_route('/*format', :conditions => {:domain => 'test-domain'})
    response = route_set.recognize(build_request({:method => 'get', :path => '/sample/html/json/apple', :domain => 'test-domain'}))
    response.params.should == [[:format, ['sample', 'html', 'json', 'apple']]]
    response.path.route.should == target_route
  end
  
  it "should recognize a format-style literal" do
    target_route = route_set.add_route('/:action.html', :controller => 'sample', :action => 'action')
    route_set.recognize(build_request({:method => 'get', :path => '/sample.html', :domain => 'admin.host.com'})).should == Usher::Node::Response.new(target_route.paths.first, [[:action , 'sample']])
  end
  
  it "should recognize a format-style variable along side another variable" do
    target_route = route_set.add_route('/:action.:format', :controller => 'sample', :action => 'action')
    route_set.recognize(build_request({:method => 'get', :path => '/sample.html', :domain => 'admin.host.com'})).should == Usher::Node::Response.new(target_route.paths.first, [[:action , 'sample'], [:format, 'html']])
  end
  
  it "should recognize a specific route when several http-style restrictions are used" do
    target_route_http_admin = route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http', :domain => 'admin.spec.com'})
    target_route_http_www = route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http', :domain => 'www.spec.com'})
    target_route_https_msie = route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:protocol => 'https', :user_agent => 'MSIE 6.0'})
    target_route_https_admin = route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:protocol => 'https', :domain => 'admin.spec.com'})
    route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http', :domain => 'admin.spec.com', :user_agent => nil})).path.route.should == target_route_http_admin
    route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http', :domain => 'www.spec.com', :user_agent => nil})).path.route.should == target_route_http_www
    route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'https', :domain => 'admin.spec.com', :user_agent => 'MSIE 6.0'})).path.route.should == target_route_https_msie
    route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'https', :domain => 'admin.spec.com', :user_agent => nil})).path.route.should == target_route_https_admin
  end
  
  it "should correctly fix that tree if conditionals are used later" do
    noop_route = route_set.add_route('/noop', :controller => 'products', :action => 'noop')
    product_show_route = route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:method => 'get'})
    route_set.recognize(build_request({:method => 'get', :path => '/noop', :domain => 'admin.host.com'})).path.route.should == noop_route
    route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :domain => 'admin.host.com'})).path.route.should == product_show_route
  end
  
  it "should use conditionals that are boolean" do
    # hijacking user_agent
    insecure_product_show_route = route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:user_agent => false, :method => 'get'})
    secure_product_show_route = route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:user_agent => true, :method => 'get'})
    
    secure_product_show_route.should == route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :domain => 'admin.host.com', :user_agent => true})).path.route
    insecure_product_show_route.should == route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :domain => 'admin.host.com', :user_agent => false})).path.route
  end
  
  it "should use conditionals that are arrays" do
    # hijacking user_agent
    www_product_show_route = route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:subdomains => ['www'], :method => 'get'})
    admin_product_show_route = route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:subdomains => ['admin'], :method => 'get'})
    
    admin_product_show_route.should == route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :subdomains => ['admin'], :user_agent => true})).path.route
    www_product_show_route.should == route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :subdomains => ['www'], :user_agent => false})).path.route
  end
  
  it "should use a requirement (proc) on incoming variables" do
    route_set.add_route('/:controller/:action/:id', :id => proc{|v| Integer(v)})
    proc {route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :domain => 'admin.host.com'}))}.should_not raise_error Usher::ValidationException
    proc {route_set.recognize(build_request({:method => 'get', :path => '/products/show/123asd', :domain => 'admin.host.com'}))}.should raise_error Usher::ValidationException
  end

  it "shouldn't care about mildly weird characters in the URL" do
    route = route_set.add_route('/!asd,qwe/hjk$qwe/:id')
    route_set.recognize(build_request({:method => 'get', :path => '/!asd,qwe/hjk$qwe/09AZaz$-_+!*\'', :domain => 'admin.host.com'})).params.rassoc('09AZaz$-_+!*\'').first.should == :id
  end
  
  it "shouldn't care about non-primary delimiters in the path" do
    route = route_set.add_route('/testing/:id/testing2/:id2/:id3')
    route_set.recognize(build_request({:method => 'get', :path => '/testing/asd.qwe/testing2/poi.zxc/oiu.asd'})).params.should == [[:id, 'asd.qwe'], [:id2, 'poi.zxc'], [:id3, 'oiu.asd']]
  end
  
  it "should should raise if malformed variables are used" do
    route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:method => 'get'})
    proc {route_set.recognize(build_request({:method => 'get', :path => '/products/show/qweasd', :domain => 'admin.host.com'}))}.should raise_error
  end
  
  
end