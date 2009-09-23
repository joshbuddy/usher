require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "usher"

describe "Usher request method" do

  it "support eql? and ==" do
    Usher::Route::RequestMethod.new(:method, 'blah').should == Usher::Route::RequestMethod.new(:method, 'blah')
    Usher::Route::RequestMethod.new(:method, 'blah').should.eql?(Usher::Route::RequestMethod.new(:method, 'blah'))
  end

  it "support hash" do
    Usher::Route::RequestMethod.new(:method, 'blah').hash.should == (Usher::Route::RequestMethod.new(:method, 'blah')).hash
  end


end
