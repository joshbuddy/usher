require 'lib/usher'

Slash = Usher::Route::Separator::Slash
Dot = Usher::Route::Separator::Dot

describe "Usher route tokenizing" do
  
  
  it "should split / delimited routes" do
    Usher::Route::Splitter.new('/test/this/split').paths.first.should == [Slash, 'test', Slash, 'this', Slash, 'split']
  end
  
  it "should group optional parts with brackets" do
    Usher::Route::Splitter.new('/test/this(/split)').paths.should == [
      [Slash, 'test', Slash, 'this'],
      [Slash, 'test', Slash, 'this', Slash, 'split']
    ]
  end

  it "should group optional parts with brackets (for non overlapping groups)" do
    Usher::Route::Splitter.new('/test/this(/split)(/split2)').paths == [
      [Slash, "test", Slash, "this"],
      [Slash, "test", Slash, "this", Slash, "split"],
      [Slash, "test", Slash, "this", Slash, "split2"],
      [Slash, "test", Slash, "this", Slash, "split", Slash, "split2"]
    ]
  end

  it "should group nested-optional parts with brackets" do
    Usher::Route::Splitter.new('/test/this(/split(.:format))').paths == [
      [Slash, "test", Slash, "this"],
      [Slash, "test", Slash, "this", Slash, "split"],
      [Slash, "test", Slash, "this", Slash, "split", Dot, Usher::Route::Variable.new(:':', :format)]
    ]
  end
  
end