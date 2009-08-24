require 'lib/usher'
require 'rack'

describe "Usher URL generation" do
  
  before(:each) do
    @route_set = Usher.new(:generator => Usher::Util::Generators::URL.new)
    @route_set.reset!
  end
  
  it "should generate a simple URL" do
    @route_set.add_named_route(:sample, '/sample', :controller => 'sample', :action => 'action')
    @route_set.generator.generate(:sample, {}).should == '/sample'
  end
  
  it "should generate a simple URL with a single variable" do
    @route_set.add_named_route(:sample, '/sample/:action', :controller => 'sample')
    @route_set.generator.generate(:sample, {:action => 'action'}).should == '/sample/action'
  end
  
  it "should generate a simple URL with a single variable (and escape)" do
    @route_set.add_named_route(:sample, '/sample/:action', :controller => 'sample')
    @route_set.generator.generate(:sample, {:action => 'action time'}).should == '/sample/action%20time'
  end
  
  it "should generate a simple URL with a single variable (thats not a string)" do
    @route_set.add_named_route(:sample, '/sample/:action/:id', :controller => 'sample')
    @route_set.generator.generate(:sample, {:action => 'action', :id => 123}).should == '/sample/action/123'
  end
  
  it "should generate a simple URL with a glob variable" do
    @route_set.add_named_route(:sample, '/sample/*action', :controller => 'sample')
    @route_set.generator.generate(:sample, {:action => ['foo', 'baz']}).should == '/sample/foo/baz'
  end
  
  it "should generate a mutliple vairable URL from a hash" do
    @route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    @route_set.generator.generate(:sample, {:first => 'zoo', :second => 'maz'}).should == '/sample/zoo/maz'
  end

  it "should generate a mutliple vairable URL from an array" do
    @route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    @route_set.generator.generate(:sample, ['maz', 'zoo']).should == '/sample/maz/zoo'
  end

  it "should generate append extra hash variables to the end" do
    @route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    @route_set.generator.generate(:sample, {:first => 'maz', :second => 'zoo', :third => 'zanz'}).should == '/sample/maz/zoo?third=zanz'
  end

  it "should generate append extra hash variables to the end (when the first parts are an array)" do
    @route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    ['/sample/maz/zoo?four=jane&third=zanz', '/sample/maz/zoo?third=zanz&four=jane'].include?(@route_set.generator.generate(:sample, ['maz', 'zoo', {:third => 'zanz', :four => 'jane'}])).should == true
  end

  it "should generate append extra hash variables to the end using [] syntax if its an array" do
    @route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    @route_set.generator.generate(:sample, {:first => 'maz', :second => 'zoo', :third => ['zanz', 'susie']}).should == '/sample/maz/zoo?third%5B%5D=zanz&third%5B%5D=susie'
  end

  it "should generate a mutliple vairable URL from an array" do
    @route_set.add_named_route(:sample, '/sample/:first/:second', :controller => 'sample')
    @route_set.generator.generate(:sample, ['maz', 'zoo']).should == '/sample/maz/zoo'
  end

  it "should generate a simple URL with a format" do
    @route_set.add_named_route(:sample, '/sample/:action.:format', :controller => 'sample')
    @route_set.generator.generate(:sample, {:action => 'action', :format => 'html'}).should == '/sample/action.html'
  end

  it "should generate from parameters" do
    caf = @route_set.add_route('/:controller/:action.:format')
    ca = @route_set.add_route('/:controller/:action')
    @route_set.generator.generate(nil, {:controller => 'controller', :action => 'action'}).should == '/controller/action'
    @route_set.generator.generate(nil, {:controller => 'controller', :action => 'action', :format => 'html'}).should == '/controller/action.html'
  end

  it "should use the first route when generating a URL from two ambiguous routes" do
    @route_set.add_route('/:controller/:action')
    @route_set.add_route('/:action/:controller')
    @route_set.generator.generate(nil, {:controller => 'controller', :action => 'action'}).should == '/controller/action'
  end

  it "should accept an array of parameters" do
    caf = @route_set.add_named_route(:name, '/:controller/:action.:format')
    @route_set.generator.generate(:name, ['controller', 'action', 'html']).should == '/controller/action.html'
  end

  it "should generate a route with a specific host" do
    caf = @route_set.add_named_route(:name, '/:controller/:action.:format', :generate_with => {:host => 'www.slashdot.org', :port => 80})
    @route_set.generator.generate_full(:name, Rack::Request.new(Rack::MockRequest.env_for("http://localhost:8080")), ['controller', 'action', 'html']).should == 'http://www.slashdot.org/controller/action.html'
  end

  it "should require all the parameters (hash) to generate a route" do
    proc{@route_set.generator.generate(@route_set.add_route('/:controller/:action'), {:controller => 'controller'})}.should raise_error(Usher::MissingParameterException)
  end

  it "should generate from a route" do
    @route_set.generator.generate(@route_set.add_route('/:controller/:action'), {:controller => 'controller', :action => 'action'}).should == '/controller/action'
  end

  it "should require all the parameters (array) to generate a route" do
    @route_set.add_named_route(:name, '/:controller/:action.:format')
    proc {@route_set.generator.generate(:name, ['controller', 'action'])}.should raise_error(Usher::MissingParameterException)
  end

  it "should generate a route when only one parameter is given" do
    @route_set.add_named_route(:name, '/:controller')
    @route_set.generator.generate(:name, 'controller').should == '/controller'
  end

  it "should generate the correct route from a route containing optional parts" do
    @route_set.add_named_route(:name, '/:controller(/:action(/:id))')
    @route_set.generator.generate(:name, {:controller => 'controller'}).should == '/controller'
    @route_set.generator.generate(:name, {:controller => 'controller', :action => 'action'}).should == '/controller/action'
    @route_set.generator.generate(:name, {:controller => 'controller', :action => 'action', :id => 'id'}).should == '/controller/action/id'
  end

  it "should generate a route using defaults for everything but the first parameter" do
    @route_set.add_named_route(:name, '/:one/:two/:three', {:default_values => {:one => 'one', :two => 'two', :three => 'three'}})
    @route_set.generator.generate(:name, {:one => "1"}).should == '/1/two/three'
  end

  it "should generate a route using defaults for everything" do
    @route_set.add_named_route(:name, '/:one/:two/:three', {:default_values => {:one => 'one', :two => 'two', :three => 'three'}})
    @route_set.generator.generate(:name).should == '/one/two/three'
  end
  
  it "should generate a route using defaults and optionals using the last parameter" do
    @route_set.add_named_route(:opts_with_defaults, '/:one(/:two(/:three))', {:default_values => {:one => '1', :two => '2', :three => '3'}})
    @route_set.generator.generate(:opts_with_defaults, {:three => 'three'}).should == '/1/2/three'
  end

  it "should generate a route with optional segments given two nested optional parameters" do
    @route_set.add_named_route(:optionals, '/:controller(/:action(/:id))(.:format)')
    @route_set.generator.generate(:optionals, {:controller => "foo", :action => "bar"}).should == '/foo/bar'
  end
  
  describe "nested generation" do
    before do
      @route_set2 = Usher.new(:generator => Usher::Util::Generators::URL.new)
      @route_set3 = Usher.new(:generator => Usher::Util::Generators::URL.new)
      @route_set4 = Usher.new(:generator => Usher::Util::Generators::URL.new)
      
      @route_set.add_named_route(:simple,   "/mount_point").match_partially!.to(@route_set2)
      @route_set.add_route("/third/:foo", :default_values => {:foo => "foo"}).match_partially!.to(@route_set3)
      @route_set.add_route("/fourth/:bar").match_partially!.to(@route_set4)
      
      @route_set2.add_named_route(:nested_simple,   "/nested/simple",     :controller => "nested",  :action => "simple")
      @route_set2.add_named_route(:nested_complex,  "/another_nested(/:complex)", :controller => "nested",  :action => "complex")
      
      @route_set3.add_named_route(:nested_simple, "/nested/simple", :controller => "nested", :action => "simple")
      @route_set3.add_named_route(:nested_complex,  "/another_nested(/:complex)", :controller => "nested",  :action => "complex")
      
      @route_set4.add_named_route(:nested_simple, "/nested/simple", :controller => "nested", :action => "simple")
    end
    
    it "should generate a route for the simple nested route" do
      @route_set2.generator.generate(:nested_simple).should == "/mount_point/nested/simple"
    end
    
    it "should generate a simple route without optional segments" do
      @route_set2.generator.generate(:nested_complex).should == "/mount_point/another_nested"
    end
    
    it "should generate a route with optional segements" do
      @route_set2.generator.generate(:nested_complex, :complex => "foo").should == "/mount_point/another_nested/foo"
    end
    
    it "should genearte a route with the specified value for the parent route" do
      @route_set3.generator.generate(:nested_simple, :foo => "bar").should == "/third/bar/nested/simple"
    end
    
    it "should generate a route with the default value from the parent route" do
      @route_set3.generator.generate(:nested_simple).should == "/third/foo/nested/simple"
    end
    
    it "should generate a route with an optional segement in the parent and child" do
      @route_set3.generator.generate(:nested_complex, :complex => "complex").should == "/third/foo/another_nested/complex"
    end
    
    it "should generate a route without the optional value from the child" do
      @route_set3.generator.generate(:nested_complex).should == "/third/foo/another_nested"
    end
    
    it "should raise an exception when trying to generate a route where the parent variable is not defined and does not have a default value" do
      lambda do
        @route_set4.generator.generate(:nested_simple)
      end.should raise_error(Usher::MissingParameterException)
    end
    
    
    
  end
end