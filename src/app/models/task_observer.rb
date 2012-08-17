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
    if a_task.changed? and change = a_task.changes['state']
      update_timestamp(change[0], change[1], a_task)
    end
  end

  def update_timestamp(state_from, state_to, a_task)
    return a_task.time_ended = Time.now if END_STATES.include? state_to
    case state_to
      when Task::STATE_RUNNING then a_task.time_started = Time.now
      when Task::STATE_PENDING then a_task.time_submitted = Time.now
      when Task::STATE_QUEUED then true
      else raise 'Unknown state: %s' % state_to
    end
  end

end

TaskObserver.instance
