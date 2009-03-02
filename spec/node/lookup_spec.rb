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

  it "should allow nil keys" do
    l = Usher::Node::Lookup.new
    l[nil] = 'qwe2'
    l['asd'] = 'qwe'
    l['asd'].should == 'qwe'
    l[nil].should == 'qwe2'
  end

  it "should be able to delete by value for hash" do
    l = Usher::Node::Lookup.new
    l[nil] = 'qwe2'
    l['asd'] = 'qwe'
    l['asd'].should == 'qwe'
    l[nil].should == 'qwe2'
    l.delete_value('qwe2')
    l[nil].should == nil
  end

  it "should be able to delete by value for hash" do
    l = Usher::Node::Lookup.new
    l[/qwe.*/] = 'qwe2'
    l['asd'] = 'qwe'
    l['asd'].should == 'qwe'
    l['qweasd'].should == 'qwe2'
    l.delete_value('qwe2')
    l['qweasd'].should == nil
  end

end