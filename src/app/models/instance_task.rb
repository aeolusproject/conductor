#
# Copyright (C) 2009 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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
    c_state = instance.portal_pool.cloud_account.connect.instance_state(state)
    if c_state
      transitions = c_state.transitions
      transitions.each do |transition|
        # FIXME if we allow actions based on the expected state after
        # automatic transitions, we need to call this method again with
        # the state from transition.to passed in.
        unless transition.action.nil?
          add_action = true
          if (instance and user)
            # FIXME: check permissions here if we filter actions by permission
          end
          actions << transition.action if add_action
        end
      end
    end
    actions
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

  # FIXME: most of these go away when ovirt model leaves
  def vm
    nil
  end
  def host
    nil
  end
  def storage_volume
    nil
  end
  def storage_pool
    nil
  end
end
