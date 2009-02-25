require 'lib/usher'

describe "Usher route tokenizing" do
  Slash = Usher::Route::Seperator::Slash
  Dot = Usher::Route::Seperator::Dot
  Method = Usher::Route::Method
  
  
  it "should split / delimited routes" do
    Usher::Route.path_to_route_parts('/test/this/split').should == [Slash, 'test', Slash, 'this', Slash, 'split', Method.for(:any)]
  end
  
  it "should group optional parts with brackets" do
    Usher::Route.path_to_route_parts('/test/this(/split)').should == [Slash, 'test', Slash, 'this', [Slash, 'split'], Method.for(:any)]
  end

  it "should group nested-optional parts with brackets" do
    Usher::Route.path_to_route_parts('/test/this(/split(.:format))').should == [Slash, 'test', Slash, 'this', [Slash, 'split', [Dot, Usher::Route::Variable.new(:':', 'format')]], Method.for(:any)]
  end
  
end