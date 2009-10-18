require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "usher"

describe Usher::Splitter, "#split" do
  describe "when there are single-character delimiters" do
    it "should split correctly" do
      Usher::Splitter.for_delimiters(['.', '/']).split('/one/two.three/').should == ['/', 'one', '/', 'two', '.', 'three', '/']
    end
  end

  describe "when there are multi-character delimiters" do
    it "should split correctly" do
      Usher::Splitter.for_delimiters(['/', '%28', '%29']).split('/one%28two%29three/').should == ['/', 'one', '%28', 'two', '%29', 'three', '/']
    end
  end

  describe "when there is no delimiter in the end" do
    it "should split correctly" do
      Usher::Splitter.for_delimiters(['.', '/']).split('/one/two.three').should == ['/', 'one', '/', 'two', '.', 'three']
    end
  end

  describe "when there is no delimiter in the beginning" do
    it "should split correctly" do
      Usher::Splitter.for_delimiters(['.', '/']).split('one/two.three/').should == ['one', '/', 'two', '.', 'three', '/']
    end
  end
end