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

class Task < ActiveRecord::Base
  belongs_to :task_target,       :polymorphic => true
  # InstanceTask association
  belongs_to :instance,          :class_name => "Instance",
                                 :foreign_key => "task_target_id"

  # moved associations here so that nested set :include directives work

  STATE_QUEUED       = "queued"
  STATE_PENDING      = "pending"
  STATE_RUNNING      = "running"
  STATE_FINISHED     = "finished"
  STATE_PAUSED       = "paused"
  STATE_FAILED       = "failed"
  STATE_CANCELED     = "canceled"

  COMPLETED_STATES = [STATE_FINISHED, STATE_FAILED, STATE_CANCELED]
  WORKING_STATES   = [STATE_QUEUED, STATE_RUNNING, STATE_PAUSED, STATE_PENDING]

  # Failures Codes
  FAILURE_PROVIDER_NOT_FOUND = "provider_not_found"
  FAILURE_PROVIDER_CONTACT_FAILED = "provider_contact_failed"
  FAILURE_PROVIDER_RETURNED_FAILED = "provider_returned_failed"

  FAILURE_OVER_POOL_QUOTA = "exceeded_pool_quota"

  FAILURE_CODES = [FAILURE_PROVIDER_NOT_FOUND, FAILURE_PROVIDER_CONTACT_FAILED, FAILURE_PROVIDER_RETURNED_FAILED, FAILURE_OVER_POOL_QUOTA]

  validates_inclusion_of :failure_code,
    :in => FAILURE_CODES + [nil]

  validates_inclusion_of :type,
   :in => %w( InstanceTask )

  validates_inclusion_of :state,
    :in => COMPLETED_STATES + WORKING_STATES

  after_initialize :initialize_state

  # FIXME validate action depending on type / subclass
  # validate task_target_id, task_type_id, arg, message
  #   depending on subclass, action, state

  TASK_STATES_OPTIONS = [["Queued", Task::STATE_QUEUED],
                         ["Pending", Task::STATE_PENDING],
                         ["Running", Task::STATE_RUNNING],
                         ["Paused", Task::STATE_PAUSED],
                         ["Finished", Task::STATE_FINISHED],
                         ["Failed", Task::STATE_FAILED],
                         ["Canceled", Task::STATE_CANCELED, "break"],
                         ["All States", ""]]

  def cancel
    update_attributes!(:state => STATE_CANCELED)
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
    "#{action}#{args.nil? ? '' : " #{args}"}"
  end

  def submission_time
    time_started - time_submitted
  end

  def runtime
    time_ended - time_started
  end

  validate :validate_task

  def validate_task
    errors.add("created_at", "Task started but does not have the creation time set") if time_started and created_at.nil?
    # Removed check on time_started exisiting. if time_ended does.  This can now occur, when the task fails before is starts.  e.g. When Over Qutoa
    #errors.add("time_started", "Task ends but does not have the start time set") if time_ended and time_started.nil?
    errors.add("time_ended", "Tasks ends before it's started") unless time_ended.nil? or time_started.nil? or time_ended >= time_started
    errors.add("time_started", "Tasks starts before it's created") unless time_started.nil? or created_at.nil? or time_started >= created_at
  end

  def initialize_state
    self.state ||= STATE_QUEUED
  end
end
