require 'spec_helper'

describe Task do

  before(:each) do
    @task = InstanceTask.new( {} )
  end

  it "should begin in a queued state" do
    @task.state.should eql('queued')
  end

  it "should be invalid with unknown type" do
    @task.should be_valid
    @task.type = 'TotallyInvalidTask'
    @task.should_not be_valid
  end

  it "should be invalid with unknown state" do
    @task.should be_valid
    @task.state = 'BetYouDidNotExpectThisState'
    @task.should_not be_valid
  end

  it "should be able to get canceled" do
    @task.cancel
    @task.state.should eql('canceled')
  end

  it "should provide a type label" do
    @task.type_label.should eql('Instance')
  end

end
