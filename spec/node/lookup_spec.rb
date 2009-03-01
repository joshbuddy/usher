require 'lib/usher'


describe "String/regexp lookup table" do

  it "should accept strings and retrieve based on them" do
    l = Usher::Node::Lookup.new
    l['asd'] = 'qwe'
    l['asd'].should == 'qwe'
  end
  
  it "should accept regexs too" do
    l = Usher::Node::Lookup.new
    l[/asd.*/] = 'qwe'
    l['asdqweasd'].should == 'qwe'
  end

  it "should prefer string to regex matches" do
    l = Usher::Node::Lookup.new
    l['asd'] = 'qwe2'
    l[/asd.*/] = 'qwe'
    l['asd'].should == 'qwe2'
  end

end