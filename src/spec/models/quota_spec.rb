#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'spec_helper'

describe Quota do

  before(:each) do
   @provider_account_quota = FactoryGirl.create :quota
   @provider_account = Factory.create(:mock_provider_account, :quota_id => @provider_account_quota.id)

   @pool_quota = FactoryGirl.create :quota
   @pool = FactoryGirl.create(:pool, :quota_id => @pool_quota.id)

   @user_quota = FactoryGirl.create :quota
   @user = FactoryGirl.create(:user, :quota_id => @user_quota.id)

   @hwp = FactoryGirl.create :mock_hwp1
   @instance = FactoryGirl.create(:new_instance, :pool => @pool, :hardware_profile => @hwp, :provider_account_id => @provider_account.id, :owner => @user)
  end

  it "should return true when asking if an instance can be created/started when there is sufficient quota space" do
    Quota.can_create_instance?(@instance, @provider_account).should == true
    Quota.can_start_instance?(@instance, @provider_account).should == true
  end

  it "should return true when asking if an instance can be created/started when using unlimited Quotas" do
    @user.quota = FactoryGirl.create :unlimited_quota
    @user.save!

    @pool.quota = FactoryGirl.create :unlimited_quota
    @pool.save!

    @provider_account.quota = FactoryGirl.create :unlimited_quota
    @provider_account.save!

    Quota.can_create_instance?(@instance, @provider_account).should == true
    Quota.can_start_instance?(@instance, @provider_account).should == true
  end

  it "should return false when asking if an instance can be created/started when the user quota is reached" do
    @user_quota.total_instances = @user_quota.maximum_total_instances
    @user_quota.running_instances = @user_quota.maximum_running_instances
    @user_quota.save!

    Quota.can_create_instance?(@instance, @provider_account).should == false
    Quota.can_start_instance?(@instance, @provider_account).should == false
  end

  it "should return false when asking if an instance can be created/started when the pool quota is reached" do
    @pool_quota.total_instances = @pool_quota.maximum_total_instances
    @pool_quota.running_instances = @pool_quota.maximum_running_instances
    @pool_quota.save!

    Quota.can_create_instance?(@instance, @provider_account).should == false
    Quota.can_start_instance?(@instance, @provider_account).should == false
  end

  it "should return false when asking if an instance can be created/started when the cloud account quota is reached" do
    @provider_account_quota.total_instances = @provider_account_quota.maximum_total_instances
    @provider_account_quota.running_instances = @provider_account_quota.maximum_running_instances
    @provider_account_quota.save!

    Quota.can_create_instance?(@instance, @provider_account).should == false
    Quota.can_start_instance?(@instance, @provider_account).should == false
  end

  it "should return false when asking if an instance can be created/started when the all quotas are reached" do
    @user_quota.total_instances = @user_quota.maximum_total_instances
    @user_quota.running_instances = @user_quota.maximum_running_instances
    @user_quota.save!

    @pool_quota.total_instances = @pool_quota.maximum_total_instances
    @pool_quota.running_instances = @pool_quota.maximum_running_instances
    @pool_quota.save!

    @provider_account_quota.total_instances = @provider_account_quota.maximum_total_instances
    @provider_account_quota.running_instances = @provider_account_quota.maximum_running_instances
    @provider_account_quota.save!

    Quota.can_create_instance?(@instance, @provider_account).should == false
    Quota.can_start_instance?(@instance, @provider_account).should == false
  end

end
