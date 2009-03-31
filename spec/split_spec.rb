require 'lib/usher'

describe "Usher route tokenizing" do
  
  
  it "should split / delimited routes" do
    Usher::Route::Splitter.new('/test/this/split').paths.first.should == ['test', 'this', 'split']
  end
  
  it "should group optional parts with brackets" do
    Usher::Route::Splitter.new('/test/this(/split)').paths.should == [
      ['test', 'this'],
      ['test', 'this', 'split']
    ]
  end

  it "should group exclusive optional parts with brackets and pipes" do
    Usher::Route::Splitter.new('/test/this(/split|/split2)').paths.should == [
      ['test', 'this', 'split'],
      ['test', 'this', 'split2']
    ]
  end

  it "should group exclusive optional-optional parts with brackets and pipes" do
    Usher::Route::Splitter.new('/test/this((/split|/split2))').paths.should == [
      ['test', 'this'],
      ['test', 'this', 'split'],
      ['test', 'this', 'split2']
    ]
  end

  it "should group optional parts with brackets (for non overlapping groups)" do
    Usher::Route::Splitter.new('/test/this(/split)(/split2)').paths == [
      ["test", "this"],
      ["test", "this", "split"],
      ["test", "this", "split2"],
      ["test", "this", "split", "split2"]
    ]
  end

  it "should group nested-optional parts with brackets" do
    Usher::Route::Splitter.new('/test/this(/split(.:format))').paths == [
      ["test", "this"],
      ["test", "this", "split"],
      ["test", "this", "split", Usher::Route::Variable.new(:'.:', :format)]
    ]
  end
  
end