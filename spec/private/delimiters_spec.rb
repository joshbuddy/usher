require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require 'usher'

describe Usher::Delimiters do
  describe "#unescaped" do
    it "should unescape delimiters correctly" do
      Usher::Delimiters.new(['/', '\)', '\\\\']).unescaped.should == ['/', ')', '\\']
    end
  end

  describe "#first_in" do
    describe "when there is a complex path with a lot of delimiters occurrences" do
      before :each do
        @delimiters = Usher::Delimiters.new ['@', '.', '/']
        @paths = ['var', '.', 'var', '/', 'var', '@']
      end

      it "should find nearest delimiter correctly" do
        @delimiters.first_in(@paths).should == '.'
        @delimiters.first_in(@paths[2..-1]).should == '/'
        @delimiters.first_in(@paths[4..-1]).should == '@'
      end
    end

    describe "when there are delimiters with escaped charaters" do
      before :each do
        @delimiters = Usher::Delimiters.new ['\\(', '\\)']
        @paths = ['var', '(', 'var', ')']
      end

      it "should find nearest delimiter in unescaped path" do
        @delimiters.first_in(@paths).should == '('
      end
    end

    describe "when there is no occurence of delimiters in path" do
      before :each do
        @delimiters = Usher::Delimiters.new ['-', '/']
        @paths = ['e', '@', 'ma', '.', 'il']
      end

      it "should return nil" do
        @delimiters.first_in(@paths).should be_nil
      end
    end
    
  end
end