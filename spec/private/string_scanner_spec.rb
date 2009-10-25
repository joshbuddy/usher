require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "usher"

describe StringScanner do
  describe "#scan_before" do
    before :each do
      @scanner = StringScanner.new("/one/two..three")
    end

    describe "when there is a match" do
      it "should return subsequent string without matching pattern in the end" do
        @scanner.scan_before(/\.\./).should == "/one/two"
      end

      it "should set pointer right before the matching pattern" do
        @scanner.scan_before(/\.\./)
        @scanner.scan(/\.\./).should == '..'
      end

      describe "when matching pattern is right at the position" do
        it "should return empty string" do
          @scanner.scan_before(/\//).should == ''
        end
      end
    end

    describe "when there is no match" do
      it "should return nil" do
        @scanner.scan_before(/bla-bla-bla/).should == nil
      end

      it "should not move the pointer" do
        @scanner.scan_before(/bla-bla-bla/)
        @scanner.pos.should == 0
      end
    end
  end
end

