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

describe InstanceObserver do

  before(:each) do
   @provider_account_quota = FactoryGirl.create :quota
   @provider_account = FactoryGirl.create(:mock_provider_account, :quota_id => @provider_account_quota.id)

   @pool_quota = FactoryGirl.create :quota
   @pool = FactoryGirl.create(:pool, :quota_id => @pool_quota.id)

   @user_quota = FactoryGirl.create :quota
   @user = FactoryGirl.create(:user, :quota_id => @user_quota.id)

   @hwp = FactoryGirl.create :mock_hwp1
   @instance = FactoryGirl.create(:new_instance, :pool => @pool, :hardware_profile => @hwp, :provider_account_id => @provider_account.id, :owner => @user)

   Timecop.travel(Time.local(2008, 9, 1, 10, 5, 0, 0, 0))
  end

  after(:each) do
    Timecop.return
  end

  it "should set started at timestamp when instance goes to state pending" do
    @instance.state = Instance::STATE_PENDING
    @instance.save!

    @instance.time_last_pending.utc.should <= Time.now.utc
  end

  it "should set started at timestamp when instance goes to state running" do
    @instance.state = Instance::STATE_RUNNING
    @instance.save!

    @instance.time_last_running.utc.should <= Time.now.utc
  end

  it "should set started at timestamp when instance goes to state shutting down" do
    @instance.state = Instance::STATE_SHUTTING_DOWN
    @instance.save!

    @instance.time_last_shutting_down.utc.should <= Time.now.utc
  end

  it "should set started at timestamp when instance goes to state stopped" do
    @instance.state = Instance::STATE_STOPPED
    @instance.save!

    @instance.time_last_stopped.utc.should <= Time.now.utc
  end

  it "should set accumlated pending time when instance changes state from state pending" do
    @instance.state = Instance::STATE_PENDING
    @instance.save!

    Timecop.freeze(Time.now + 1.second)

    @instance.state = Instance::STATE_RUNNING
    @instance.save!
    @instance.acc_pending_time.should >= 1
    @instance.acc_pending_time.should <= 2
  end

  it "should set accumlated running time when instance changes state from state running" do
    @instance.state = Instance::STATE_RUNNING
    @instance.save!

    Timecop.freeze(Time.now + 1.second)

    @instance.state = Instance::STATE_SHUTTING_DOWN
    @instance.save!

    @instance.acc_running_time.should >= 1
    @instance.acc_running_time.should <= 2
  end

  it "should set accumlated shutting down time when instance changes state from state shutting down" do
    @instance.state = Instance::STATE_SHUTTING_DOWN
    @instance.save!

    Timecop.freeze(Time.now + 1.second)

    @instance.state = Instance::STATE_STOPPED
    @instance.save!

    @instance.acc_shutting_down_time.should >= 1
    @instance.acc_shutting_down_time.should <= 2
  end

  it "should set accumlated stopped time when instance changes state from state stopped" do
    @instance.state = Instance::STATE_STOPPED
    @instance.save!

    Timecop.freeze(Time.now + 1.second)

    @instance.state = Instance::STATE_PENDING
    @instance.save!

    @instance.acc_stopped_time.should >= 1
    @instance.acc_stopped_time.should <= 2
  end

  it "should not update quota on pool, user and cloud account when an instance is state new" do
    [@provider_account_quota, @pool_quota, @user_quota].each do |quota|
      quota = Quota.find(quota)
      quota.total_instances.should == 0
    end
  end

  it "should update quota on pool, user and cloud account when an instance goes to state pending" do
    [@provider_account_quota, @pool_quota, @user_quota].each do |quota|
      @instance.state = Instance::STATE_PENDING
      @instance.save!

      quota = Quota.find(quota)
      quota.total_instances.should == 1
    end
  end

  it "should update cloud accoun, pool  and user quota when an instance goes into an inactive state" do
    @instance.state = Instance::STATE_CREATE_FAILED
    @instance.save!

    [@provider_account_quota, @pool_quota, @user_quota].each do |quota|
      quota = Quota.find(quota)
      quota.total_instances.should == 0
    end
  end

  it "should update pool, cloud account and user quota when an instance state goes to running" do
    @instance.state = Instance::STATE_RUNNING
    @instance.save!

    [@provider_account_quota, @pool_quota, @user_quota].each do |quota|
      quota = Quota.find(quota.id)
      quota.running_instances.should == 1
      quota.total_instances.should == 1
    end
  end

  it "should not update pool, cloud account and user quota when an instance state goes from pending to running to shutting down" do
    @instance.state = Instance::STATE_PENDING
    @instance.save!

    @instance.state = Instance::STATE_RUNNING
    @instance.save!

    @instance.state = Instance::STATE_SHUTTING_DOWN
    @instance.save!

    [@provider_account_quota, @pool_quota, @user_quota].each do |quota|
      quota = Quota.find(quota.id)
      quota.running_instances.should == 1
      quota.total_instances.should == 1
    end
  end


  it "should update a pool, cloud account and user quota when an instance state goes from running to stopped state" do
    @instance.state = Instance::STATE_RUNNING
    @instance.save!

    @instance.state = Instance::STATE_STOPPED
    @instance.save!

    [@provider_account_quota, @pool_quota, @user_quota].each do |quota|
      quota = Quota.find(quota.id)

      quota.running_instances.should == 0
      quota.total_instances.should == 1
    end
  end

  it "should track the events of the instance lifetime" do
    @instance.events.should have(1).items
    @instance.events[0].summary.should match /created/

    @instance.state = Instance::STATE_RUNNING
    @instance.save!

    @instance = Instance.find(@instance.id)
    @instance.events.should have(2).items
    @instance.events[1].summary.should match /state.*running/

    @instance.state = Instance::STATE_STOPPED
    @instance.save!

    @instance = Instance.find(@instance.id)
    @instance.events.should have(3).items
    @instance.events[2].summary.should match /state.*stopped/
  end

  it "should destroy the instance key when the instance is stopped" do
    @instance = FactoryGirl.create :mock_running_instance
    @instance.instance_key.should_not be_nil
    @instance.state = Instance::STATE_STOPPED
    @instance.save!
    @instance.instance_key.reload
    @instance.instance_key.should be_nil
  end

  it "should create event when one of deployment's instance stop/fail'" do
    deployment = Factory :deployment
    instance1 = Factory :mock_running_instance, :deployment => deployment
    instance2 = Factory :mock_running_instance, :deployment => deployment
    instance3 = Factory :mock_pending_instance, :deployment => deployment
    instance3.state = Instance::STATE_RUNNING
    instance3.save!
    instance2.state = Instance::STATE_ERROR
    instance2.save!
    deployment.events.last.status_code.should == "some_stopped"
  end

end
