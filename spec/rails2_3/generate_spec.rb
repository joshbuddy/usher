require File.expand_path(File.join(File.dirname(__FILE__), 'compat'))
require "usher"

route_set = Usher::Interface.for(:rails23)

describe "Usher (for rails 2.3) URL generation" do
  
  before(:each) do
    route_set.reset!
  end

  it "should fill in the controller from recall" do
    route_set.add_route('/:controller/:action/:id')
    route_set.generate({:action => 'thingy'}, {:controller => 'sample', :action => 'index', :id => 123}, :generate).should == '/sample/thingy'
  end

  it "should skip the action if not provided" do
    route_set.add_route('/:controller/:action/:id')
    route_set.generate({:controller => 'thingy'}, {:controller => 'sample', :action => 'index', :id => 123}, :generate).should == '/thingy'
  end

  it "should pick the correct param from optional parts" do
    route_set.add_route('/:controller/:action(.:format)')
    route_set.generate({:action => 'thingy', :format => 'html'}, {:controller => 'sample', :action => 'index', :id => 123}, :generate).should == '/sample/thingy.html'
    route_set.generate({:action => 'thingy'}, {:controller => 'sample', :action => 'index', :id => 123}, :generate).should == '/sample/thingy'
  end

  it "should generate routes based on name with a hash" do
    route_set.add_named_route(:test, '/:test1/:test2', :controller => 'sample', :action => 'index')
    generator = Class.new
    route_set.install_helpers(generator, true)
    generator.new.test_url('one', 'two').should == '/one/two'
    generator.new.test_url('one', 'two', :three => 'four').should == '/one/two?three=four'
  end

end
