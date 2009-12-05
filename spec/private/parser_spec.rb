require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))
require "usher"

describe "Usher route tokenizing" do
  
  
  it "should split / delimited routes" do
    Usher.new(:delimiters => ['/', '.'], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('/test/this/split').should == [['/', 'test', '/','this', '/', 'split']]
  end

  it "should split / delimited routes with a regex in it" do
    Usher.new(:delimiters => ['/', '.'], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('/test/{this}/split').should == [['/', 'test', '/', /this/, '/', 'split']]
  end
  
  it "should split on ' ' delimited routes as well" do
    Usher.new(:delimiters => [' '], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('test this split').should == [['test', ' ', 'this', ' ', 'split']]
  end
  
  it "should split on email delimiters as well" do
    Usher.new(:delimiters => ['@', '+', '-', '.'], :valid_regex => '[a-zA-Z0-9]+').parser.parse_and_expand('one+more.12345-09876-alphanum3ric5@domain.com').should == [["one", '+', "more", ".", "12345", '-', "09876", '-', "alphanum3ric5", "@", "domain", ".", "com"]]
  end
  
  it "should split on ' ' delimited routes for more complex routes as well" do
    Usher.new(:delimiters => [' '], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('(test|this) split').should == [['test', ' ', 'split'], ['this', ' ', 'split']]
  end

  it "should correctly handle multichar delimiters as well" do
    Usher.new(:delimiters => ['%28', '%29'], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('cheese%28parmesan%29').should == [['cheese', '%28', 'parmesan', '%29']]    
  end
  
  it "should group optional parts with brackets" do
    Usher.new(:delimiters => ['/', '.'], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('/test/this(/split)').should == [
      ['/', 'test', '/', 'this'],
      ['/', 'test', '/', 'this', '/', 'split']
    ]
  end

  it "should group exclusive optional parts with brackets and pipes" do
    Usher.new(:delimiters => ['/', '.'], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('/test/this(/split|/split2)').should == [
      ['/', 'test', '/', 'this','/', 'split'],
      ['/', 'test', '/', 'this','/', 'split2']
    ]
  end

  it "should group exclusive optional-optional parts with brackets and pipes" do
    Usher.new(:delimiters => ['/', '.'], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('/test/this((/split|/split2))').should == [
      ['/', 'test','/', 'this'],
      ['/', 'test','/', 'this', '/', 'split'],
      ['/', 'test','/', 'this', '/', 'split2']
    ]
  end

  it "should group optional parts with brackets (for non overlapping groups)" do
    Usher.new(:delimiters => ['/', '.'], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('/test/this(/split)(/split2)') == [
      ['/', "test", '/', "this"],
      ['/', "test", '/', "this", '/', "split"],
      ['/', "test", '/', "this", '/', "split2"],
      ['/', "test", '/', "this", '/', "split", '/', "split2"]
    ]
  end

  it "should group nested-optional parts with brackets" do
    Usher.new(:delimiters => ['/', '.'], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('/test/this(/split(.:format))') == [
      ['/', "test", '/', "this"],
      ['/', "test", '/', "this", '/', "split"],
      ['/', "test", '/', "this", '/', "split", '.', Usher::Route::Variable::Single.new(:format)]
    ]
  end

  it "should to_s all different variable types" do
    Usher.new(:delimiters => ['/', '.'], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('/:split/*splitter').first.collect{|v| v.to_s} == 
      [ ':split', '*splitter' ]
  end
  
  it "should == variable types" do
    parts = Usher.new(:delimiters => ['/', '.'], :valid_regex => '[0-9A-Za-z\$\-_\+!\*\',]+').parser.parse_and_expand('/:split/:split').first
    parts[1].should == parts[3]
  end
  
  it "should let me escape reserved characters" do
    Usher.new.parser.parse_and_expand('/my\/thing/is\*lovingyou').should == [["/", "my/thing", "/", "is*lovingyou"]]
  end

  it "should let me use escaped characters as delimiters" do
    Usher.new(:delimiters => ['/', '\(', '\)']).parser.parse_and_expand('/cheese\(:kind\)').should == [['/', 'cheese', '(', Usher::Route::Variable::Single.new(:kind), ')']]
  end

  describe "#generate_route" do
    describe "when delimiters contain escaped characters" do
      before :each do
        @parser = Usher.new(:delimiters => ['/', '\(', '\)']).parser
      end

      it "should correctly generate route with a variable" do
        route = @parser.generate_route('/cheese\(:kind\)', nil, nil, nil, nil, nil)        
        variable = route.paths[0].parts[3]
        
        variable.should be_kind_of(Usher::Route::Variable::Single)        
        variable.look_ahead.should == ')'
      end
    end
  end
end