describe "a route destination" do
  before(:each) do
    @u = Usher.new
  end

  it "should return a compound with given var args" do
    r = @u.add_route('/testsauce').to(:one, :two, :three, :four)
    r.destination.args.should  == [:one, :two, :three, :four]
  end
  
  it "should return a compound with given var args and a hash on the end" do
    r = @u.add_route('/testsauce').to(:one, :two, :three, :four, :five => 'six', :seven => 'heaven')
    r.destination.args.should  == [:one, :two, :three, :four]
    r.destination.options.should  == {:five => 'six', :seven => 'heaven'}
  end

  it "should never wrap it in a compound if its a simple hash" do
    r = @u.add_route('/testsauce').to(:five => 'six', :seven => 'heaven')
    r.destination.should  == {:five => 'six', :seven => 'heaven'}
  end

  it "should never wrap it in a compound if its a simple object" do
    r = @u.add_route('/testsauce').to(:eighteen)
    r.destination.should  == :eighteen
  end

  it "should never wrap it in a compound if its a simple block" do
    p = proc{ puts 'lovetown' }
    r = @u.add_route('/testsauce').to(&p)
    r.destination.should == p
  end
end