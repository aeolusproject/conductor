require 'spec_helper'

describe InstanceObserver do

  before(:each) do
   @timestamp = Time.now

   @cloud_account_quota = Factory :quota
   @cloud_account = Factory(:mock_cloud_account, :quota_id => @cloud_account_quota.id)

   @pool_quota = Factory :quota
   @pool = Factory(:pool, :quota_id => @pool_quota.id)

   @hwp = Factory :mock_hwp1
   @instance = Factory(:new_instance, :pool => @pool, :hardware_profile => @hwp, :cloud_account_id => @cloud_account.id)
  end

  it "should set started at timestamp when instance goes to state pending" do
    @instance.state = Instance::STATE_PENDING
    @instance.save

    @instance.time_last_pending.should >= @timestamp
  end

  it "should set started at timestamp when instance goes to state running" do
    @instance.state = Instance::STATE_RUNNING
    @instance.save

    @instance.time_last_running.should >= @timestamp
  end

  it "should set started at timestamp when instance goes to state shutting down" do
    @instance.state = Instance::STATE_SHUTTING_DOWN
    @instance.save

    @instance.time_last_shutting_down.should >= @timestamp
  end

  it "should set started at timestamp when instance goes to state stopped" do
    @instance.state = Instance::STATE_STOPPED
    @instance.save

    @instance.time_last_stopped.should >= @timestamp
  end

  it "should set accumlated pending time when instance changes state from state pending" do
    @instance.state = Instance::STATE_PENDING
    @instance.save

    sleep(1)

    @instance.state = Instance::STATE_RUNNING
    @instance.save

    @instance.acc_pending_time.should >= 1
    @instance.acc_pending_time.should <= 2
  end

  it "should set accumlated running time when instance changes state from state running" do
    @instance.state = Instance::STATE_RUNNING
    @instance.save

    sleep(1)

    @instance.state = Instance::STATE_SHUTTING_DOWN
    @instance.save!

    @instance.acc_running_time.should >= 1
    @instance.acc_running_time.should <= 2
  end

  it "should set accumlated shutting down time when instance changes state from state shutting down" do
    @instance.state = Instance::STATE_SHUTTING_DOWN
    @instance.save;

    sleep(1)

    @instance.state = Instance::STATE_STOPPED
    @instance.save

    @instance.acc_shutting_down_time.should >= 1
    @instance.acc_shutting_down_time.should <= 2
  end

  it "should set accumlated stopped time when instance changes state from state stopped" do
    @instance.state = Instance::STATE_STOPPED
    @instance.save

    sleep(1)

    @instance.state = Instance::STATE_PENDING
    @instance.save

    @instance.acc_stopped_time.should >= 1
    @instance.acc_stopped_time.should <= 2
  end

  it "should not update quota on pool and cloud account when an instance is state new" do
    [@cloud_account_quota, @pool_quota].each do |quota|
      quota = Quota.find(quota)

      quota.total_instances.should == 0
      quota.total_storage.to_f.should == 0.to_f
    end
  end

  it "should update quota on pool and cloud account when an instance fgoes to state pending" do
    [@cloud_account_quota, @pool_quota].each do |quota|
      @instance.state = Instance::STATE_PENDING
      @instance.save

      quota = Quota.find(quota)

      quota.total_instances.should == 1
      quota.total_storage.to_f.should == @hwp.storage.value.to_f
    end
  end

  it "should update cloud account and pool quota when an instance goes into an inactive state" do
    @instance.state = Instance::STATE_CREATE_FAILED
    @instance.save!

    [@cloud_account_quota, @pool_quota].each do |quota|
      quota = Quota.find(quota)

      quota.total_instances.should == 0
      quota.total_storage.to_f.should == 0.to_f
    end
  end

  it "should update pool and cloud account quota when an instance state goes to running" do
    @instance.state = Instance::STATE_RUNNING
    @instance.save!

    [@cloud_account_quota, @pool_quota].each do |quota|
      quota = Quota.find(quota.id)
      quota.running_instances.should == 1
      quota.running_memory.to_f.should == @hwp.memory.value.to_f
      quota.running_cpus.to_f.should == @hwp.cpu.value.to_f

      quota.total_storage.to_f.should == @hwp.storage.value.to_f
      quota.total_instances.should == 1
    end
  end

  it "should update a pool and cloud account quota when an instance state goes from running to another active state" do
    @instance.state = Instance::STATE_RUNNING
    @instance.save!

    @instance.state = Instance::STATE_SHUTTING_DOWN
    @instance.save!

    [@cloud_account_quota, @pool_quota].each do |quota|
      quota = Quota.find(quota.id)

      #TODO test for cpus
      quota.running_instances.should == 0
      quota.running_memory.to_f.should == 0.to_f

      quota.total_storage.to_f.should == @hwp.storage.value.to_f
      quota.total_instances.should == 1
    end
  end

end