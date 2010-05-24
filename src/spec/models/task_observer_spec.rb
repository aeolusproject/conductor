require 'spec_helper'

describe TaskObserver do

  before(:each) do
    @timestamp = Time.now
    @task = InstanceTask.new({})
  end

  it "should set started at timestamp when the task goes to state running" do
    @task.state = Task::STATE_RUNNING
    @task.save

    @task.time_started.should >= @timestamp
  end

  it "should set time submitted timestamp when the task goes to state pending" do
    @task.state = Task::STATE_PENDING
    @task.save

    @task.time_submitted.should >= @timestamp
  end

    it "should set ended timestamp when the task has finished" do
    @task.state = Task::STATE_FINISHED
    @task.save

    @task.time_ended.should >= @timestamp
  end

  it "should set ended timestamp when the task is cancelled" do
    @task.state = Task::STATE_CANCELED
    @task.save

    @task.time_ended.should >= @timestamp
  end

  it "should set ended timestamp when the task has failed" do
    @task.state = Task::STATE_FAILED
    @task.save

    @task.time_ended.should >= @timestamp
  end

end