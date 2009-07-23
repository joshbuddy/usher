require 'lib/usher'

def build_email_mock(email)
  request = mock "Request"
  request.should_receive(:email).any_number_of_times.and_return(email)
  request
end

describe "Usher (for email) route recognition" do

  before(:each) do
    @route_set = Usher::Interface.for(:email)
  end

  it "should recognize a simple request" do
    receiver = mock('receiver')
    receiver.should_receive(:action).with({}).exactly(1)
    @route_set.for('joshbuddy@gmail.com') { |params| receiver.action(params) }
    @route_set.act('joshbuddy@gmail.com')
  end

  it "should recognize a wildcard domain" do
    receiver = mock('receiver')
    receiver.should_receive(:action).with({:domain => 'gmail.com'}).exactly(1)
    @route_set.for('joshbuddy@*domain') { |params| receiver.action(params) }
    @route_set.act('joshbuddy@gmail.com')
  end

  it "should recognize a complex email" do
    receiver = mock('receiver')
    receiver.should_receive(:action).with({:subject => 'sub+ect', :id => '123', :sid => '456', :tok => 'sdqwe123ae', :domain => 'mydomain.org'}).exactly(1)
    @route_set.for(':subject.{:id,^\d+$}-{:sid,^\d+$}-{:tok,^\w+$}@*domain') { |params| receiver.action(params) }
    @route_set.act('sub+ect.123-456-sdqwe123ae@mydomain.org')
  end

end