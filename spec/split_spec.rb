require 'lib/usher'

describe "Usher route tokenizing" do
  Slash = Usher::Route::Seperator::Slash
  Dot = Usher::Route::Seperator::Dot
  Method = Usher::Route::Method
  
  
  it "should split / delimited routes" do
    Usher::Route::Split.new('/test/this/split').paths.first.should == [Slash, 'test', Slash, 'this', Slash, 'split', Method.for(:any)]
  end
  
  it "should group optional parts with brackets" do
    Usher::Route::Split.new('/test/this(/split)').paths.should == [
      [Slash, 'test', Slash, 'this', Method.for(:any)],
      [Slash, 'test', Slash, 'this', Slash, 'split', Method.for(:any)]
    ]
  end

  it "should group optional parts with brackets (for non overlapping groups)" do
    Usher::Route::Split.new('/test/this(/split)(/split2)').paths == [
      [Slash, "test", Slash, "this", Method.for(:any)],
      [Slash, "test", Slash, "this", Slash, "split", Method.for(:any)],
      [Slash, "test", Slash, "this", Slash, "split2", Method.for(:any)],
      [Slash, "test", Slash, "this", Slash, "split", Slash, "split2", Method.for(:any)]
    ]
  end

  it "should group nested-optional parts with brackets" do
    Usher::Route::Split.new('/test/this(/split(.:format))').paths == [
      [Slash, "test", Slash, "this", Method.for(:any)],
      [Slash, "test", Slash, "this", Slash, "split", Method.for(:any)],
      [Slash, "test", Slash, "this", Slash, "split", Dot, Usher::Route::Variable.new(:':', :format), Method.for(:any)]
    ]
  end
  
end