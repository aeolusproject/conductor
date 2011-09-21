#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

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
