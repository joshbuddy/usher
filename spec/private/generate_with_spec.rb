require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "usher"

describe Usher::Route::GenerateWith, "#empty?" do
  before :all do
    ::GenerateWith = Usher::Route::GenerateWith
  end

  describe "when all fields are nil" do
    before :each do
      @empty_generate_with = GenerateWith.new
    end

    it "should return true" do
      @empty_generate_with.empty?.should be_true
    end
  end

  describe "when at least one field is filled" do
    before :each do
      @filled_generate_with = GenerateWith.new('http')
    end

    it "should return false" do
      @filled_generate_with.empty?.should be_false
    end
  end
end
