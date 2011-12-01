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

describe Task do

  before(:each) do
    @valid_attributes = { :created_at => Time.now,
      :time_started => Time.now + 3.minutes,
      :time_ended => Time.now + 5.minutes,
      :state => Task::STATE_FINISHED }
    @task = InstanceTask.new( {} )
  end

  it "should be valid with the test data" do
    @task.attributes = @valid_attributes
    @task.should be_valid
  end

  it "should begin in a queued state" do
    @task.state.should eql('queued')
  end

  it "should be invalid with unknown type" do
    @task.type = 'TotallyInvalidTask'
    @task.should_not be_valid
  end

  it "should be invalid with unknown state" do
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

  it "should have 'created at' time set if it started" do
    @task.attributes = @valid_attributes.except :created_at
    @task.should_not be_valid
  end

  it "should not be valid if it started before it was created" do
    @task.attributes = @valid_attributes
    @task.time_started = @task.created_at - 1.minute
    @task.should_not be_valid
  end

  it "should not be valid if it ended before it was started" do
    @task.attributes = @valid_attributes
    @task.time_ended = @task.time_started - 1.minute
    @task.should_not be_valid
  end


end
