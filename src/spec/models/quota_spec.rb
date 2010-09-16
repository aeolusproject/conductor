require 'spec_helper'

describe Quota do

  before(:each) do
   @cloud_account_quota = Factory :quota
   @cloud_account = Factory(:mock_cloud_account, :quota_id => @cloud_account_quota.id)

   @pool_quota = Factory :quota
   @pool = Factory(:pool, :quota_id => @pool_quota.id)

   @user_quota = Factory :quota
   @user = Factory(:user, :quota_id => @user_quota.id)

   @hwp = Factory :mock_hwp1
   @instance = Factory(:new_instance, :pool => @pool, :hardware_profile => @hwp, :cloud_account_id => @cloud_account.id, :owner => @user)
  end

  it "should return true when asking if an instance can be created/started when there is sufficient quota space" do
    Quota.can_create_instance?(@instance).should == true
    Quota.can_start_instance?(@instance).should == true
  end

  it "should return false when asking if an instance can be created/started when the user quota is reached" do
    @user_quota.total_instances = @user_quota.maximum_total_instances
    @user_quota.running_instances = @user_quota.maximum_running_instances
    @user_quota.save!

    Quota.can_create_instance?(@instance).should == false
    Quota.can_start_instance?(@instance).should == false
  end

  it "should return false when asking if an instance can be created/started when the pool quota is reached" do
    @pool_quota.total_instances = @pool_quota.maximum_total_instances
    @pool_quota.running_instances = @pool_quota.maximum_running_instances
    @pool_quota.save!

    Quota.can_create_instance?(@instance).should == false
    Quota.can_start_instance?(@instance).should == false
  end

  it "should return false when asking if an instance can be created/started when the cloud account quota is reached" do
    @cloud_account_quota.total_instances = @cloud_account_quota.maximum_total_instances
    @cloud_account_quota.running_instances = @cloud_account_quota.maximum_running_instances
    @cloud_account_quota.save!

    Quota.can_create_instance?(@instance).should == false
    Quota.can_start_instance?(@instance).should == false
  end

  it "should return false when asking if an instance can be created/started when the all quotas are reached" do
    @user_quota.total_instances = @user_quota.maximum_total_instances
    @user_quota.running_instances = @user_quota.maximum_running_instances
    @user_quota.save!

    @pool_quota.total_instances = @pool_quota.maximum_total_instances
    @pool_quota.running_instances = @pool_quota.maximum_running_instances
    @pool_quota.save!

    @cloud_account_quota.total_instances = @cloud_account_quota.maximum_total_instances
    @cloud_account_quota.running_instances = @cloud_account_quota.maximum_running_instances
    @cloud_account_quota.save!

    Quota.can_create_instance?(@instance).should == false
    Quota.can_start_instance?(@instance).should == false
  end

end