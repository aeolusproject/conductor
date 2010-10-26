require 'spec_helper'

describe RegistrationService do

  before(:all) do
    MetadataObject.delete_all
    Role.delete_all
    Factory.create(:default_quota_metadata)
    Factory.create(:default_role_metadata)
    Factory.create(:default_pool_metadata)
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
          end.should change(Permission, :count).by(1)
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

    before(:all) do
      ActiveSupport::TestCase.use_transactional_fixtures = false
    end

    after(:all) do
      ActiveSupport::TestCase.use_transactional_fixtures = true
    end

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
