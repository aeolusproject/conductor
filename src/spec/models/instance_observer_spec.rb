require 'spec_helper'

describe InstanceObserver do

  before(:each) do
   @timestamp = Time.now
   @instance = Factory :new_instance
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
    @instance.save

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
end