require 'spec_helper'

describe RegistrationService do

  before(:each) do
  end

  describe "with validations" do

    it "should return errors on user when user is missing required fields" do
      user = User.new(:login => 'baduser')
      r = RegistrationService.new(user)
      r.save.should be_false
      user.errors.empty?.should be_false
      user.errors.find_all do |attr,msg|
        ["email","password","password_confirmation"].include?(attr).should be_true
      end
    end

    it "should register a user with default pool/quota/role/template perms when default settings set" do
      @user = Factory :user
      @pool = MetadataObject.lookup("self_service_default_pool")
      @role = MetadataObject.lookup("self_service_default_role")
      @quota = Factory :quota
      MetadataObject.set("self_service_default_quota", @quota)

      @registration_service = RegistrationService.new(@user)
      @registration_service.save

      @pools = Pool.list_for_user(@user, Privilege::CREATE, :target_type => Instance)
      @pools.length.should == 1
      @pools[0].name.should == "default_pool"

      @user.quota.maximum_running_instances.should == @quota.maximum_running_instances
      @user.quota.maximum_total_instances.should == @quota.maximum_total_instances
      BasePermissionObject.general_permission_scope.has_privilege(@user,Privilege::CREATE, Template).should == true
      BasePermissionObject.general_permission_scope.has_privilege(@user,Privilege::USE, Template).should == true
    end

  end

  describe "with quota" do

    it "passed via nested attributes to user model" do
      user_attributes = Factory.attributes_for(:user)
      user_attributes[:quota_attributes] = {}
      user_attributes[:quota_attributes][:maximum_running_instances] = 2
      user_attributes[:quota_attributes][:maximum_total_instances] = 5
      user = User.new(user_attributes)
      registration_process = RegistrationService.new(user)

      lambda do
        lambda do
          lambda do
            registration_process.save.should be_true
          end.should change(Permission, :count).by(2)
        end.should change(User, :count).by(1)
      end.should change(Quota, :count).by(1)

      user.new_record?.should be_false
      user.quota.maximum_running_instances.should == 2
      user.quota.maximum_total_instances.should == 5
    end

    it "no quota attributes passed via nested attributes" do
      user = Factory.build(:user)
      registration_process = RegistrationService.new(user)

      lambda do
        registration_process.save.should be_true
      end.should_not change(Quota, :count)

      user.quota.maximum_running_instances.should == 10
      user.quota.maximum_total_instances.should == 15
    end
  end

  describe "with transaction" do

    it "doesn't save user if quota save! raise error and return false if validation failed" do
      user_attributes = Factory.attributes_for(:user)
      user = User.new(user_attributes)
      registration_process = RegistrationService.new(user)

      q = Quota.new(:maximum_total_instances => 'error')
      Quota.should_receive(:new).and_return(q)

      lambda do
        registration_process.save.should be_false
      end.should_not change(User, :count)
    end

    it "doesn't save quota if user save! raise error" do
      user_attributes = Factory.attributes_for(:user)
      user = User.new(user_attributes)
      user.should_receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(user))
      registration_process = RegistrationService.new(user)

      lambda do
        lambda do
          registration_process.save.should be_false
        end.should_not change(Quota, :count)
      end.should_not change(User, :count)
    end

  end

end
