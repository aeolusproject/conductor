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

class TaskObserver < ActiveRecord::Observer

  END_STATES = [ Task::STATE_CANCELED, Task::STATE_FAILED, Task::STATE_FINISHED ]

  def before_save(a_task)
    if a_task.changed?
      change = a_task.changes['state']
      if change
        update_timestamp(change[0], change[1], a_task)
      end
    end
  end

  def update_timestamp(state_from, state_to, a_task)
    if state_to == Task::STATE_RUNNING
      a_task.time_started = Time.now
    elsif state_to == Task::STATE_PENDING
      a_task.time_submitted = Time.now
    elsif END_STATES.include?(state_to)
      a_task.time_ended = Time.now
    end
  end

end

TaskObserver.instance
