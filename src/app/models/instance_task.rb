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

# == Schema Information
# Schema version: 20110207110131
#
# Table name: tasks
#
#  id               :integer         not null, primary key
#  user             :string(255)
#  type             :string(255)
#  action           :string(255)
#  state            :string(255)
#  task_target_id   :integer
#  task_target_type :string(255)
#  args             :string(255)
#  created_at       :datetime
#  time_submitted   :datetime
#  time_started     :datetime
#  time_ended       :datetime
#  message          :text
#  failure_code     :string(255)
#  lock_version     :integer         default(0)
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class InstanceTask < Task

  ACTION_CREATE       = "create"

  ACTION_START        = "start"
  ACTION_STOP         = "stop"
  ACTION_REBOOT       = "reboot"
  ACTION_DESTROY      = "destroy"
  # FIXME: do we need this for db-omatic?
  ACTION_UPDATE_STATE = "update_state"



  def task_obj
    if self.instance
      "Instance;;;#{self.instance.id};;;#{self.instance.name}"
    else
      ""
    end
  end

  # FIXME: sort out pending_state issue w/ instance here including
  # automatic transitions from transient states.
  def self.valid_actions_for_instance_state(state, instance, user=nil)
    actions = []
    # FIXME: cloud_account won't always be set here, but we're requiring
    #        front end realm for now.
    if cloud_account = instance.provider_account and
      conn = cloud_account.connect and c_state = conn.instance_state(dc_version_compatible_state(conn,state))
        transitions = c_state.transitions
        transitions.each do |transition|
          # FIXME if we allow actions based on the expected state after
          # automatic transitions, we need to call this method again with
          # the state from transition.to passed in.
          next unless transition.action
          next if instance.state == Instance::STATE_PENDING
          actions << transition.action
        end
    end
    actions
  end

  #this method translate states so they are compatible with 0.5.x and 1.x version of dc-core
  #v0.5.x use state shutting_down, v1.x changed the state to stopping
  def self.dc_version_compatible_state(connection,state)
    if state == Instance::STATE_SHUTTING_DOWN && connection.api_version.to_i >= 1
      Instance::STATE_STOPPING
    else
      state
    end
  end

  def self.action_label(action)
    return ACTIONS[action][:label]
  end
  def self.action_icon(action)
    return ACTIONS[action][:icon]
  end
  def self.label_and_action(action)
    return [action_label(action), action, action_icon(action)]
  end

  # FIXME: need to pass in provider to filter start and destroy out for ec2
  def self.get_instance_actions
    return [["Start", InstanceTask::ACTION_START],
            ["Stop", InstanceTask::ACTION_STOP],
            ["Reboot", InstanceTask::ACTION_REBOOT_VM],
            ["Destroy", InstanceTask::ACTION_DESTROY]]
  end
end
