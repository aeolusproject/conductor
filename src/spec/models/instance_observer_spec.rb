require 'spec_helper'

describe InstanceObserver do

  before(:each) do
   @timestamp = Time.now
   @instance = Factory :pending_instance
  end

  it "should set started at timestamp when instance goes to state running" do
    @instance.state = Instance::STATE_RUNNING
    @instance.save

    @instance.time_last_start.should >= @timestamp
  end

  it "should set accumlated run time when instance goes to from state running to state stopped" do
    @instance.state = Instance::STATE_RUNNING
    @instance.save;

    sleep(2)

    @instance.state = Instance::STATE_STOPPED
    @instance.save

    @instance.acc_run_time.should >= 2
  end

end