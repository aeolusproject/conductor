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
      it "should create user, pool and self-service permission" do
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

      it "should return pool errors if pool create fails" do
        #TODO: implement this test.  We should check this, but not sure of best
        # way right now.
      end
    end
  end

  it "should register a user with default pool/quota/role when default settings set" do
    @user = Factory :user
    @pool = Factory(:pool, :name => "default_pool")
    @role = Role.find_by_name("Instance Creator and User")
    @quota = Factory :quota

    MetadataObject.set("allow_self_service_logins", "true")
    MetadataObject.set("self_service_default_pool", @pool)
    MetadataObject.set("self_service_default_role", @role)
    MetadataObject.set("self_service_default_quota", @quota)

    @registration_service = RegistrationService.new(@user)
    @registration_service.save

    @pools = Pool.list_for_user(@user, Privilege::INSTANCE_VIEW)
    @pools.size.should == 1
    @pools[0].name.should == "default_pool"

    @user.quota.maximum_running_instances.should == @quota.maximum_running_instances
    @user.quota.maximum_total_instances.should == @quota.maximum_total_instances
  end
end
