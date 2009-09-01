#
# Copyright (C) 2008 Red Hat, Inc.
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

class Task < ActiveRecord::Base
  belongs_to :task_target,       :polymorphic => true
  # InstanceTask association
  belongs_to :instance,          :class_name => "Instance",
                                 :foreign_key => "task_target_id"

  # moved associations here so that nested set :include directives work

  STATE_QUEUED       = "queued"
  STATE_RUNNING      = "running"
  STATE_FINISHED     = "finished"
  STATE_PAUSED       = "paused"
  STATE_FAILED       = "failed"
  STATE_CANCELED     = "canceled"

  COMPLETED_STATES = [STATE_FINISHED, STATE_FAILED, STATE_CANCELED]
  WORKING_STATES   = [STATE_QUEUED, STATE_RUNNING, STATE_PAUSED]

  validates_inclusion_of :type,
   :in => %w( InstanceTask )

  validates_inclusion_of :state,
    :in => COMPLETED_STATES + WORKING_STATES

  # FIXME validate action depending on type / subclass
  # validate task_target_id, task_type_id, arg, message
  #   depending on subclass, action, state

  TASK_STATES_OPTIONS = [["Queued", Task::STATE_QUEUED],
                         ["Running", Task::STATE_RUNNING],
                         ["Paused", Task::STATE_PAUSED],
                         ["Finished", Task::STATE_FINISHED],
                         ["Failed", Task::STATE_FAILED],
                         ["Canceled", Task::STATE_CANCELED, "break"],
                         ["All States", ""]]

  def initialize(params)
    super
    self.state = STATE_QUEUED unless self.state
  end

  def cancel
    self[:state] = STATE_CANCELED
    save!
  end

  def self.working_tasks(user = nil)
    self.tasks_for_states(Task::WORKING_STATES, user)
  end

  def self.completed_tasks(user = nil)
    self.tasks_for_states(Task::COMPLETED_STATES, user)
  end

  def self.tasks_for_states(state_array, user = nil)
    conditions = state_array.collect {|x| "state='#{x}'"}.join(" or ")
    conditions = "(#{conditions}) and user='#{user}'"
    Task.find(:all, :conditions => conditions)
  end

  def type_label
    self.class.name[0..-5]
  end
  def task_obj
    ""
  end

  def action_with_args
    ret_val = action
    ret_val += " #{args}" if args
    ret_val
  end

  def validate
    errors.add("time_ended", "Tasks ends before it's started") unless time_ended.nil? or time_started.nil? or time_ended > time_started
    errors.add("time_started", "Tasks starts before it's created") unless time_started.nil? or created_at.nil? or time_started > created_at
  end
end
