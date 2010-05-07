require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "usher"

describe "Usher metadata" do

  it "should add meta data to a path" do
    usher = Usher.new
    usher.add_route('/test')
    usher.add_route('/test/test2')
    usher.add_route('/test/test3')
    usher.add_route('/test/test2/:variable')
    usher.add_meta(:test, '/test')
    usher.add_meta(:test2, '/test/test2')
    usher.add_meta(:test3, '/test/test2/:something')
    
    usher.recognize_path('/test').meta.should == [:test]
    usher.recognize_path('/test/test3').meta.should == [:test]
    usher.recognize_path('/test/test2').meta.should == [:test, :test2]
    usher.recognize_path('/test/test2/variable1').meta.should == [:test, :test2, :test3]
    usher.recognize_path('/test/test2/variable2').meta.should == [:test, :test2, :test3]
    
  end
end
