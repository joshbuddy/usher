require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require 'usher'

describe Delimiters do
  describe "#unescaped" do
    it "should unescape delimiters correctly" do
      Delimiters.new(['/', '\)', '\\\\']).unescaped.should == ['/', ')', '\\']
    end
  end
end