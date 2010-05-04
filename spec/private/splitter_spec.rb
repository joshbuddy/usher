require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "usher"

describe Usher::Splitter, "#split" do
  describe "when there are single-character delimiters" do
    it "should split correctly" do
      Usher::Splitter.new(['.', '/']).split('/one/two.three/').should == ['/', 'one', '/', 'two', '.', 'three', '/']
    end
  end

  describe "when there are multi-character delimiters" do
    it "should split correctly" do
      Usher::Splitter.new(['/', '%28', '%29']).split('/one%28two%29three/').should == ['/', 'one', '%28', 'two', '%29', 'three', '/']
    end
  end

  describe "when there is no delimiter in the end" do
    it "should split correctly" do
      Usher::Splitter.new(['.', '/']).split('/one/two.three').should == ['/', 'one', '/', 'two', '.', 'three']
    end
  end

  describe "when there is no delimiter in the beginning" do
    it "should split correctly" do
      Usher::Splitter.new(['.', '/']).split('one/two.three/').should == ['one', '/', 'two', '.', 'three', '/']
    end
  end

  describe "when delimiters are consecutive" do
    it "should split correctly" do
      Usher::Splitter.new(['/', '!']).split('/cheese/!parmesan').should == ['/', 'cheese', '/', '!', 'parmesan']
    end
  end

  describe "when delimiters contain escaped characters" do
    it "should split correctly" do
      Usher::Splitter.new(['/', '\(', '\)']).split('/cheese(parmesan)').should == ['/', 'cheese', '(', 'parmesan', ')']
    end
  end
end