require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "usher"

def build_request(opts)
  request = mock "Request"
  opts.each do |k,v|
    request.should_receive(k).any_number_of_times.and_return(v)
  end
  request
end

describe "Usher route recognition" do

  before(:each) do
    @route_set = Usher.new(:request_methods => [:protocol, :domain, :port, :query_string, :remote_ip, :user_agent, :referer, :method, :subdomains])
  end

  describe 'request conditions' do

    it "should ignore an unrecognized route" do
      target_route = @route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http'}).unrecognizable!
      @route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http'})).should be_nil
    end

    it "should recognize a specific domain name" do
      target_route = @route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:protocol => 'http'})
      @route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:protocol => 'https'})
      @route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http'})).path.route.should == target_route
    end

    it "should recognize a regex domain name" do
      target_route = @route_set.add_route('/sample', :controller => 'sample', :action => 'action', :conditions => {:domain => /^admin.*$/})
      @route_set.add_route('/sample', :controller => 'sample', :action => 'action2', :conditions => {:domain => 'www.host.com'})
      @route_set.recognize(build_request({:method => 'get', :path => '/sample', :domain => 'admin.host.com'})).path.route.should == target_route
    end

    it "should recognize a specific route when several http-style restrictions are used" do
      target_route_http_admin_generic = @route_set.add_route('/sample', :conditions => {:domain => 'admin.spec.com'})
      target_route_http_admin = @route_set.add_route('/sample', :conditions => {:protocol => 'http', :domain => 'admin.spec.com'})
      target_route_http_www = @route_set.add_route('/sample', :conditions => {:protocol => 'http', :domain => 'www.spec.com'})
      target_route_https_msie = @route_set.add_route('/sample', :conditions => {:protocol => 'https', :domain => 'admin.spec.com', :user_agent => 'MSIE 6.0'})
      target_route_https_admin = @route_set.add_route('/sample', :conditions => {:protocol => 'https', :domain => 'admin.spec.com'})
      @route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http', :domain => 'admin.spec.com', :user_agent => nil})).path.route.should == target_route_http_admin
      @route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http', :domain => 'www.spec.com', :user_agent => nil})).path.route.should == target_route_http_www
      @route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'https', :domain => 'admin.spec.com', :user_agent => 'MSIE 6.0'})).path.route.should == target_route_https_msie
      @route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'https', :domain => 'admin.spec.com', :user_agent => nil})).path.route.should == target_route_https_admin
      @route_set.recognize(build_request({:method => 'put', :path => '/sample', :protocol => 'wacky', :domain => 'admin.spec.com', :user_agent => nil})).path.route.should == target_route_http_admin_generic

    end

    it "should recognize an empty path" do
      @route_set.add_route('').to(:test)
      @route_set.recognize(build_request({:path => ''})).path.route.destination.should == :test
    end

    it "should recognize an optionally empty path" do
      @route_set.add_route('(/)').to(:test)
      @route_set.recognize(build_request({:path => ''})).path.route.destination.should == :test
      @route_set.recognize(build_request({:path => '/'})).path.route.destination.should == :test
    end

    it "should correctly fix that tree if conditionals are used later" do
      noop_route = @route_set.add_route('/noop', :controller => 'products', :action => 'noop')
      product_show_route = @route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:method => 'get'})
      @route_set.recognize(build_request({:method => 'get', :path => '/noop', :domain => 'admin.host.com'})).path.route.should == noop_route
      @route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :domain => 'admin.host.com'})).path.route.should == product_show_route
    end

    it "should use conditionals that are boolean" do
      # hijacking user_agent
      insecure_product_show_route = @route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:user_agent => false, :method => 'get'})
      secure_product_show_route = @route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:user_agent => true, :method => 'get'})

      secure_product_show_route.should == @route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :domain => 'admin.host.com', :user_agent => true})).path.route
      insecure_product_show_route.should == @route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :domain => 'admin.host.com', :user_agent => false})).path.route
    end

    it "should use flatten and use conditionals that are arrays" do
      # hijacking user_agent
      www_product_show_route = @route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:subdomains => ['www', 'admin'], :method => 'get'})

      www_product_show_route.should == @route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :subdomains => 'admin', :user_agent => true})).path.route
      www_product_show_route.should == @route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :subdomains => 'www', :user_agent => false})).path.route
    end
  end

  describe 'when proc' do

    it "pick the correct route" do
      not_target_route = @route_set.add_route('/sample').when{|r| r.protocol == 'https'}
      target_route =     @route_set.add_route('/sample').when{|r| r.protocol == 'http'}
      @route_set.recognize(build_request({:method => 'get', :path => '/sample', :protocol => 'http'})).path.route.should == target_route
    end
  end

  it "should recognize path with a trailing slash" do
    @route_set = Usher.new(:request_methods => [:protocol, :domain, :port, :query_string, :remote_ip, :user_agent, :referer, :method, :subdomains], :ignore_trailing_delimiters => true)

    target_route = @route_set.add_route('/path', :controller => 'sample', :action => 'action')

    response = @route_set.recognize(build_request({:method => 'get', :path => '/path/'}))
    response.path.route.should == target_route
  end

  it "should recognize a format-style variable" do
    target_route = @route_set.add_route('/sample.:format', :controller => 'sample', :action => 'action')
    response = @route_set.recognize(build_request({:method => 'get', :path => '/sample.html', :domain => 'admin.host.com'}))
    response.path.should == target_route.paths.first
    response.params.should == [[:format, 'html']]
  end

  it "should recognize a glob-style variable" do
    target_route = @route_set.add_route('/sample/*format', :controller => 'sample', :action => 'action')
    @route_set.recognize(build_request({:method => 'get', :path => '/sample/html/json/apple'})).params.should == [[:format, ['html', 'json', 'apple']]]
  end

  it "should recognize variables between multi-char delimiters" do
    @route_set = Usher.new(:delimiters => ['%28', '%29', '/', '.'])
    target_route = @route_set.add_route('/cheese%28:kind%29', :controller => 'sample', :action => 'action')

    response = @route_set.recognize(build_request({:method => 'get', :path => '/cheese%28parmesan%29'}))
    response.path.route.should == target_route
    response.params.should == [[:kind , 'parmesan']]
  end

  it "should recognize route with escaped characters as delimiters" do
    @route_set = Usher.new(:delimiters => ['/', '.', '\\(', '\\)'])

    target_route = @route_set.add_route('/cheese\\(:kind\\)', :controller => 'sample', :action => 'action')

    response = @route_set.recognize(build_request({:method => 'get', :path => '/cheese(parmesan)'}))
    response.should_not be_nil
    response.path.route.should == target_route
    response.params.should == [[:kind , 'parmesan']]
  end

  it "should recognize route with consecutive delimiters" do
    @route_set = Usher.new(:delimiters => ['!', '/'])
    target_route = @route_set.add_route('/cheese/!:kind', :controller => 'sample', :action => 'action')

    response = @route_set.recognize(build_request({:method => 'get', :path => '/cheese/!parmesan'}))
    response.path.route.should == target_route
    response.params.should == [[:kind , 'parmesan']]
  end

  it "should recgonize only a glob-style variable" do
    target_route = @route_set.add_route('/*format')
    response = @route_set.recognize(build_request({:method => 'get', :path => '/sample/html/json/apple'}))
    response.params.should == [[:format, ['sample', 'html', 'json', 'apple']]]
    response.path.route.should == target_route
  end

  it "should recgonize a regex static part" do
    target_route = @route_set.add_route('/test/part/{one|two}')
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/one'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/two'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/three'})).should == nil
  end

  it "should recgonize a two identical regex static parts distinguished by request methods" do
    get_route = @route_set.add_route('/test1/{:val,test}', :conditions => {:method => 'get'})
    post_route = @route_set.add_route('/test1/{:val,test}', :conditions => {:method => 'post'})
    @route_set.recognize(build_request({:method => 'get', :path => '/test1/test'})).path.route.should == get_route
    @route_set.recognize(build_request({:method => 'post', :path => '/test1/test'})).path.route.should == post_route
  end

  it "shouldn't accept a nil variable" do
    target_route = @route_set.add_route('/:one')
    @route_set.recognize(build_request({:method => 'get', :path => '/one'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/'})).should == nil
  end

  it "should recgonize a regex static part containing {}'s" do
    target_route = @route_set.add_route('/test/part/{oo,^o{2,3}$}')
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/oo'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/ooo'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/oooo'})).should == nil
  end

  it "should recgonize a regex single variable" do
    target_route = @route_set.add_route('/test/part/{:test,hello|again}')
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello'})).params.should == [[:test, 'hello']]
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/again'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/again'})).params.should == [[:test, 'again']]
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/world'})).should == nil
  end

  it "should recgonize a regex glob variable" do
    target_route = @route_set.add_route('/test/part/{*test,^(hello|again|\d+)$}')
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again'})).params.should == [[:test, ['hello', 'again', '123', 'hello', 'again']]]
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/agaim/123/hello/again'})).should == nil
  end

  it "should recgonize a regex glob variable terminated by a static part" do
    target_route = @route_set.add_route('/test/part/{*test,^(hello|again|\d+)$}/onemore')
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again/onemore'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again/onemore'})).params.should == [[:test, ['hello', 'again', '123', 'hello', 'again']]]
  end

  it "should recgonize a regex glob variable terminated by a single regex variable" do
    target_route = @route_set.add_route('/test/part/{*test,^(hello|again|\d+)$}/{:party,onemore}')
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again/onemore'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/hello/again/123/hello/again/onemore'})).params.should == [[:test, ['hello', 'again', '123', 'hello', 'again']], [:party, 'onemore']]
  end

  it "should recgonize a greedy regex single variable" do
    target_route = @route_set.add_route('/test/part/{!test,one/more/time}')
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/one/more/time'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/one/more/time'})).params.should == [[:test, 'one/more/time']]
  end

  it "should recgonize a greedy regex that matches across / and not" do
    target_route = @route_set.add_route('/test/part/{!test,one/more|one}')
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/one/more'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/one/more'})).params.should == [[:test, 'one/more']]
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/one'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/one'})).params.should == [[:test, 'one']]
  end

  it "should recgonize a greedy regex single variable with static parts after" do
    target_route = @route_set.add_route('/test/part/{!test,one/more/time}/help')
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/one/more/time/help'})).path.route.should == target_route
    @route_set.recognize(build_request({:method => 'get', :path => '/test/part/one/more/time/help'})).params.should == [[:test, 'one/more/time']]
  end

  it "should recgonize two glob-style variables separated by a static part" do
    target_route = @route_set.add_route('/*format/innovate/*onemore')
    response = @route_set.recognize(build_request({:method => 'get', :path => '/sample/html/innovate/apple'}))
    response.params.should == [[:format, ['sample', 'html']], [:onemore, ['apple']]]
    response.path.route.should == target_route
  end

  it "should recgonize only a glob-style variable with a condition" do
    target_route = @route_set.add_route('/*format', :conditions => {:domain => 'test-domain'})
    response = @route_set.recognize(build_request({:method => 'get', :path => '/sample/html/json/apple', :domain => 'test-domain'}))
    response.params.should == [[:format, ['sample', 'html', 'json', 'apple']]]
    response.path.route.should == target_route
  end

  it "should recognize a format-style literal" do
    target_route = @route_set.add_route('/:action.html', :controller => 'sample', :action => 'action')
    response = @route_set.recognize(build_request({:method => 'get', :path => '/sample.html', :domain => 'admin.host.com'}))
    response.path.should == target_route.paths.first
    response.params.should == [[:action, 'sample']]
  end

  it "should recognize a format-style variable along side another variable" do
    target_route = @route_set.add_route('/:action.:format', :controller => 'sample', :action => 'action')
    response = @route_set.recognize(build_request({:method => 'get', :path => '/sample.html', :domain => 'admin.host.com'}))
    response.path.should == target_route.paths.first
    response.params.should == [[:action, 'sample'], [:format, 'html']]
  end

  it "should use a requirement (proc) on incoming variables" do
    @route_set.add_route('/:controller/:action/:id', :id => proc{|v| Integer(v)})
    proc {@route_set.recognize(build_request({:method => 'get', :path => '/products/show/123', :domain => 'admin.host.com'}))}.should_not raise_error(Usher::ValidationException)
    proc {@route_set.recognize(build_request({:method => 'get', :path => '/products/show/123asd', :domain => 'admin.host.com'}))}.should raise_error(Usher::ValidationException)
  end

  it "shouldn't care about mildly weird characters in the URL" do
    route = @route_set.add_route('/!asd,qwe/hjk$qwe/:id')
    @route_set.recognize(build_request({:method => 'get', :path => '/!asd,qwe/hjk$qwe/09AZaz$-_+!*\'', :domain => 'admin.host.com'})).params.rassoc('09AZaz$-_+!*\'').first.should == :id
  end

  it "shouldn't care about non-primary delimiters in the path" do
    route = @route_set.add_route('/testing/:id/testing2/:id2/:id3')
    @route_set.recognize(build_request({:method => 'get', :path => '/testing/asd.qwe/testing2/poi.zxc/oiu.asd'})).params.should == [[:id, 'asd.qwe'], [:id2, 'poi.zxc'], [:id3, 'oiu.asd']]
  end

  it "should pick the path when there are mutliple conflicting delimiters" do
    @route_set.add_route('/:id1(.:format)')
    @route_set.add_route('/:id1/one(.:format)')
    @route_set.add_route('/:id1/one/:id2(.:format)')

    @route_set.recognize(build_request({:path => '/id1'})).params.should == [[:id1, 'id1']]
    @route_set.recognize(build_request({:path => '/id1.html'})).params.should == [[:id1, 'id1'], [:format, 'html']]
    @route_set.recognize(build_request({:path => '/id1/one'})).params.should == [[:id1, 'id1']]
    @route_set.recognize(build_request({:path => '/id1/one.html'})).params.should == [[:id1, 'id1'], [:format, 'html']]
    @route_set.recognize(build_request({:path => '/id1/one/id2'})).params.should == [[:id1, 'id1'], [:id2, 'id2']]
    @route_set.recognize(build_request({:path => '/id1/one/id2.html'})).params.should == [[:id1, 'id1'], [:id2, 'id2'], [:format, 'html']]
  end

  it "should pick the correct variable name when there are two variable names that could be represented" do
    @route_set.add_route('/:var1')
    @route_set.add_route('/:var2/foo')
    @route_set.recognize(build_request({:path => '/foo1'})).params.should == [[:var1, 'foo1']]
    @route_set.recognize(build_request({:path => '/foo2/foo'})).params.should == [[:var2, 'foo2']]
  end

  it "should recognize a path with an optional compontnet" do
    @route_set.add_route("/:name(/:surname)", :conditions => {:method => 'get'})
    result = @route_set.recognize(build_request({:method => 'get', :path => '/homer'}))
    result.params.should == [[:name, "homer"]]
    result = @route_set.recognize(build_request({:method => 'get', :path => "/homer/simpson"}))
    result.params.should == [[:name, "homer"],[:surname, "simpson"]]
  end

  it "should use a regexp requirement as part of recognition" do
    @route_set.add_route('/products/show/:id', :id => /\d+/, :conditions => {:method => 'get'})
    @route_set.recognize(build_request({:method => 'get', :path => '/products/show/qweasd', :domain => 'admin.host.com'})).should be_nil
  end

  it "should use a inline regexp and proc requirement as part of recognition" do
    @route_set.add_route('/products/show/{:id,^\d+$}', :id => proc{|v| v == '123'}, :conditions => {:method => 'get'})
    proc { @route_set.recognize(build_request({:method => 'get', :path => '/products/show/234', :domain => 'admin.host.com'}))}.should raise_error(Usher::ValidationException)
  end

  it "should not allow the use of an inline regexp and regexp requirement as part of recognition" do
    proc { @route_set.add_route('/products/show/{:id,^\d+$}', :id => /\d+/, :conditions => {:method => 'get'}) }.should raise_error(Usher::DoubleRegexpException)
  end

  it "should recognize multiple optional parts" do
    target_route = @route_set.add_route('/test(/this)(/too)')
    @route_set.recognize_path('/test').path.route.should == target_route
    @route_set.recognize_path('/test/this').path.route.should == target_route
    @route_set.recognize_path('/test/too').path.route.should == target_route
    @route_set.recognize_path('/test/this/too').path.route.should == target_route
  end

  it "should match between two routes where one is more specific from request conditions" do
    route_with_post = @route_set.add_route("/foo", :conditions => {:method => 'post'})
    route = @route_set.add_route("/foo")

    @route_set.recognize(build_request({:method => 'post', :path => '/foo'})).path.route.should == route_with_post
    @route_set.recognize(build_request({:method => 'get', :path => '/foo'})).path.route.should == route
  end

  it "should match between two routes where one has a higher priroty" do
    route_lower = @route_set.add_route("/foo", :conditions => {:protocol => 'https'}, :priority => 1)
    route_higher = @route_set.add_route("/foo", :conditions => {:method => 'post'}, :priority => 2)

    @route_set.recognize(build_request({:method => 'post', :protocol => 'https', :path => '/foo'})).path.route.should == route_higher

    @route_set.reset!

    route_higher = @route_set.add_route("/foo", :conditions => {:protocol => 'https'}, :priority => 2)
    route_lower = @route_set.add_route("/foo", :conditions => {:method => 'post'}, :priority => 1)

    @route_set.recognize(build_request({:method => 'post', :protocol => 'https', :path => '/foo'})).path.route.should == route_higher

    @route_set.reset!
  end

  it "should only match the specified path of the route when a condition is specified" do
    @route_set.add_route("/", :conditions => {:method => "get"})
    @route_set.add_route("/foo")

    @route_set.recognize(build_request(:method => "get", :path => "/asdf")).should be_nil
  end

  it "should match a variable inbetween two secondary delimiters" do
    @route_set.add_route("/o.:slug.gif").to(:test)
    response = @route_set.recognize(build_request(:method => "get", :path => "/o.help.gif"))
    response.destination.should == :test
    response.params.should == [[:slug, "help"]]
  end
  
  it "should match a route with no path" do
    route = @route_set.add_route(nil, :conditions => {:protocol => 'http'}).to(:test)
    @route_set.recognize(build_request({:method => 'post', :protocol => 'http', :path => '/foo'})).destination.should == :test
    @route_set.recognize(build_request({:method => 'post', :protocol => 'http', :path => '/bar'})).destination.should == :test
    @route_set.recognize(build_request({:method => 'post', :protocol => 'https', :path => '/foo'})).should be_nil
  end
  
  describe "partial recognition" do
    it "should partially match a route" do
      route = @route_set.add_route("/foo")
      route.match_partially!
      response = @route_set.recognize(build_request(:method => "get", :path => "/foo/bar"))
      response.partial_match?.should be_true
      response.params.should == []
      response.remaining_path.should == '/bar'
      response.matched_path.should == '/foo'
    end

    it "should partially match a route and use request conditions" do
      route = @route_set.add_route("/foo", :conditions => {:method => 'get'})
      route.match_partially!

      @route_set.recognize(build_request({:method => 'get', :path => '/foo/bar'})).path.route.should == route
      @route_set.recognize(build_request({:method => 'post', :path => '/foo/bar'})).should.nil?
    end

    it "should not match partially when a route is not set as partially matched" do
      route = @route_set.add_route("/foo", :foo => :bar)
      @route_set.recognize(build_request(:path => "/foo")).path.route.should == route
      @route_set.recognize(build_request(:path => "/foo/bar")).should be_nil
    end

  end

  describe "dup safety" do
    before do
      @route_set.add_route("/foo", :foo => "foo")
      @r2 = @route_set.dup
    end

    it "should provide a different object" do
      @route_set.should_not eql(@r2)
    end

    it "should recognize the originals routes in the dup" do
      @route_set.recognize(  build_request(:path => "/foo")).path.route.destination.should == {:foo =>"foo"}
      @r2.recognize(        build_request(:path => "/foo")).path.route.destination.should == {:foo =>"foo"}
    end

    it "should not add routes added to the dup to the original" do
      @r2.add_route("/bar", :bar => "bar")
      @r2.recognize(       build_request(:path => "/bar")).path.route.destination.should == {:bar => "bar"}
      @route_set.recognize(build_request(:path => "/bar")).should == nil
    end

    it "should not delete routes added to the dup to the original" do
      @r2.delete_route("/foo")
      @route_set.recognize(build_request(:path => "/foo")).path.route.destination.should == {:foo => "foo"}
      @r2.recognize(       build_request(:path => "/foo")).should == nil
    end


    it "should safely dup with nested ushers" do
      r1 = Usher.new
      r2 = Usher.new
      r3 = Usher.new

      r1.add_route("/mounted"           ).match_partially!.to(r2)
      r2.add_route("/inner"             ).match_partially!.to(r3)
      r3.add_route("/baz", :baz => :baz )

      r1.recognize(build_request(:path => "/mounted/inner")).path.route.destination.should == r2
      r4 = r1.dup
      r4.recognize(build_request(:path => "/mounted/inner")).path.route.destination.should == r2
      r4.add_route("/r3").match_partially!.to(r3)
      r4.recognize(build_request(:path => "/r3")).path.route.destination.should == r3
      r1.recognize(build_request(:path => "/r3")).should be_nil
    end

  end

end
