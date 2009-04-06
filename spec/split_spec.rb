require 'lib/usher'

describe "Usher route tokenizing" do
  
  
  it "should split / delimited routes" do
    Usher::Splitter.for_delimiters(['/', '.']).split('/test/this/split').should == [[:/, 'test', :/,'this', :/, 'split']]
  end
  
  it "should split on ' ' delimited routes as well" do
    Usher::Splitter.for_delimiters([' ']).split('test this split').should == [['test', :' ', 'this', :' ', 'split']]
  end
  
  it "should split on ' ' delimited routes for more complex routes as well" do
    Usher::Splitter.for_delimiters([' ']).split('(test|this) split').should == [['test', :' ', 'split'], ['this', :' ', 'split']]
  end
  
  it "should group optional parts with brackets" do
    Usher::Splitter.for_delimiters(['/', '.']).split('/test/this(/split)').should == [
      [:/, 'test', :/, 'this'],
      [:/, 'test', :/, 'this', :/, 'split']
    ]
  end

  it "should group exclusive optional parts with brackets and pipes" do
    Usher::Splitter.for_delimiters(['/', '.']).split('/test/this(/split|/split2)').should == [
      [:/, 'test', :/, 'this',:/, 'split'],
      [:/, 'test', :/, 'this',:/, 'split2']
    ]
  end

  it "should group exclusive optional-optional parts with brackets and pipes" do
    Usher::Splitter.for_delimiters(['/', '.']).split('/test/this((/split|/split2))').should == [
      [:/, 'test',:/, 'this'],
      [:/, 'test',:/, 'this', :/, 'split'],
      [:/, 'test',:/, 'this', :/, 'split2']
    ]
  end

  it "should group optional parts with brackets (for non overlapping groups)" do
    Usher::Splitter.for_delimiters(['/', '.']).split('/test/this(/split)(/split2)') == [
      [:/, "test", :/, "this"],
      [:/, "test", :/, "this", :/, "split"],
      [:/, "test", :/, "this", :/, "split2"],
      [:/, "test", :/, "this", :/, "split", :/, "split2"]
    ]
  end

  it "should group nested-optional parts with brackets" do
    Usher::Splitter.for_delimiters(['/', '.']).split('/test/this(/split(.:format))') == [
      [:/, "test", :/, "this"],
      [:/, "test", :/, "this", :/, "split"],
      [:/, "test", :/, "this", :/, "split", '.', Usher::Route::Variable.new(:':', :format)]
    ]
  end
  
end