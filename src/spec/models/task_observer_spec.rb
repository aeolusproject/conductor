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
