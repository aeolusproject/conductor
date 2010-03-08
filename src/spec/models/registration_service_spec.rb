require 'spec_helper'

describe RegistrationService do
  fixtures :all
  before(:each) do
    @tuser = Factory :tuser
  end

  it "should initialize a new instance given valid attributes" do
    RegistrationService.new(@tuser)
  end

  describe "#save" do

    context "adding valid user with no errors" do
      it "should create user, portal_pool and self-service permission" do
        user = User.new({:login => 'gooduser',
                        :email => 'guser@example.com',
                        :password => 'password',
                        :password_confirmation => 'password'})
        r = RegistrationService.new(user)
      end
    end

    context "save fails" do
      it "should return errors on user when user is missing required field" do
        user = User.new(:login => 'baduser')
        r = RegistrationService.new(user)
        r.save.should be_false
        user.errors.empty?.should be_false
        user.errors.find_all {|attr,msg|
	  ["email", "password",  "password_confirmation"].include?(attr).should be_true
	}
      end

      it "should return portal_pool errors if pool create fails" do
        #TODO: implement this test.  We should check this, but not sure of best
        # way right now.
      end
    end
  end
end
