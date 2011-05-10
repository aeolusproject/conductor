# == Schema Information
# Schema version: 20110207110131
#
# Table name: instances
#
#  id                      :integer         not null, primary key
#  external_key            :string(255)
#  name                    :string(1024)    not null
#  hardware_profile_id     :integer         not null
#  template_id             :integer
#  frontend_realm_id       :integer
#  owner_id                :integer
#  pool_id                 :integer         not null
#  provider_account_id     :integer
#  instance_hwp_id         :integer
#  public_addresses        :string(255)
#  private_addresses       :string(255)
#  state                   :string(255)
#  condor_job_id           :string(255)
#  last_error              :text
#  lock_version            :integer         default(0)
#  acc_pending_time        :integer         default(0)
#  acc_running_time        :integer         default(0)
#  acc_shutting_down_time  :integer         default(0)
#  acc_stopped_time        :integer         default(0)
#  time_last_pending       :datetime
#  time_last_running       :datetime
#  time_last_shutting_down :datetime
#  time_last_stopped       :datetime
#  created_at              :datetime
#  updated_at              :datetime
#  assembly_id             :integer
#  deployment_id           :integer
#

#
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'sunspot_rails'
class Instance < ActiveRecord::Base
  include SearchFilter
  include PermissionedObject

  searchable do
    text :name, :as => :code_substring
    text :external_key, :as => :code_substring
    text :public_addresses, :as => :code_substring
    text :private_addresses, :as => :code_substring
    text :state, :as => :code_substring
    text :owner do
      owner.last_name + " " + owner.first_name
    end
  end

  cattr_reader :per_page
  @@per_page = 15

  belongs_to :pool
  belongs_to :provider_account
  belongs_to :deployment

  belongs_to :hardware_profile
  belongs_to :template
  belongs_to :assembly
  belongs_to :frontend_realm
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  belongs_to :instance_hwp

  has_one :instance_key, :as => :instance_key_owner, :dependent => :destroy
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :events, :as => :source, :dependent => :destroy
  after_create "assign_owner_roles(owner)"

  validates_presence_of :pool_id
  validates_presence_of :hardware_profile_id
  validates_presence_of :template_id, :unless => :deployment_id
  validates_presence_of :assembly_id, :if => :deployment_id

  #validates_presence_of :external_key
  # TODO: can we do uniqueness validation on indirect association
  # -- pool.account.provider
  #validates_uniqueness_of :external_key, :scope => :provider_id

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :pool_id
  validates_length_of :name, :maximum => 1024

  STATE_NEW            = "new"
  STATE_PENDING        = "pending"
  STATE_RUNNING        = "running"
  STATE_SHUTTING_DOWN  = "shutting_down"
  STATE_STOPPED        = "stopped"
  STATE_CREATE_FAILED  = "create_failed"
  STATE_ERROR          = "error"

  STATES = [STATE_NEW, STATE_PENDING, STATE_RUNNING,
             STATE_SHUTTING_DOWN, STATE_STOPPED, STATE_CREATE_FAILED,
             STATE_ERROR]

  SEARCHABLE_COLUMNS = %w(name state)

  validates_inclusion_of :state,
     :in => STATES

  before_destroy :destroyable?

  # A user should only be able to update certain attributes, but the API may permit other attributes to be
  # changed if called from another Aeolus component, so attr_protected isn't quite what we want:
  USER_MUTABLE_ATTRS = ['name']

  def validate
    if assembly and template
      errors.add(:assembly, "Please specify either template or assembly, but not both")
      errors.add(:template, "Please specify either template or assembly, but not both")
    end
  end

  def object_list
    super + [pool, deployment]
  end
  class << self
    alias orig_list_for_user_include list_for_user_include
    alias orig_list_for_user_conditions list_for_user_conditions
  end

  def self.list_for_user_include
    includes = orig_list_for_user_include
    includes << { :pool => {:permissions => {:role => :privileges}},
                  :deployment => {:permissions => {:role => :privileges}}}
    includes
  end

  def self.list_for_user_conditions
    "(#{orig_list_for_user_conditions}) or
     (permissions_deployments.user_id=:user and
      privileges_roles.target_type=:target_type and
      privileges_roles.action=:action) or
     (permissions_pools.user_id=:user and
      privileges_roles_2.target_type=:target_type and
      privileges_roles_2.action=:action)"
  end

  def get_action_list(user=nil)
    # return empty list rather than nil
    # FIXME: not handling pending state now -- only current state
    return_val = InstanceTask.valid_actions_for_instance_state(state,
                                                               self,
                                                               user) || []
    # filter actions based on quota
    # FIXME: not doing quota filtering now
    return_val
  end

  # Provide method to check if requested action exists, so caller can decide
  # if they want to throw an error of some sort before continuing
  # (ie in service api)
  def valid_action?(action)
    return get_action_list.include?(action) ? true : false
  end

  def queue_action(user, action, data = nil)
    return false unless get_action_list.include?(action)
    task = InstanceTask.new({ :user        => user,
                              :task_target => self,
                              :action      => action,
                              :args        => data})
    task.save!
    return task
  end

  # Returns the total time that this instance has been in the state
  def total_state_time(state)

    if !STATES.include?(state)
      return "Error, could not calculate state time: invalid state"
    end

    case state
      when STATE_PENDING
        if self.state == STATE_PENDING
          return acc_pending_time + (Time.now - time_last_pending)
        else
          return acc_pending_time
        end

      when STATE_RUNNING
        if self.state == STATE_RUNNING
          return acc_running_time + (Time.now - time_last_running)
        else
          return acc_running_time
        end

      when STATE_SHUTTING_DOWN
        if self.state == STATE_SHUTTING_DOWN
          return acc_shutting_down_time + (Time.now - time_last_shutting_down)
        else
          return acc_shutting_down_time
        end

      when STATE_STOPPED
        if self.state == STATE_STOPPED
          return acc_stopped_time + (Time.now - time_last_stopped)
        else
          return acc_stopped_time
        end

      else
        return "Error, could not calculate state time: state is not monitored"
    end
  end

  def create_unique_key
    return unless self.provider_account and self.provider_account.instance_key
    # deltacloud/ec2 api's create_key method returns only private part of
    # key -> we don't know public part, so we generate new ssh key
    # and replace whole authorized_keys file
    key_name = "#{self.name}_rsa_#{Time.now.to_f}"
    self.instance_key = InstanceKey.new(self.provider_account.instance_key.attributes.merge({
      :instance_key_owner => self,
      :name => key_name
    }))
    begin
      self.instance_key.replace_key(self.public_addresses, self.provider_account.instance_key.pem)
      self.events.create!(:summary => "successfully updated ssh key", :event_time  => Time.now)
    rescue
      msg = "failed to upload ssh key: #{$!}"
      self.last_error = msg
      self.events.create!(:summary => msg, :event_time  => Time.now)
    ensure
      # if replace_key fails, we still save instance_key - should be copy of
      # provider_account key which was used when launching instance
      self.instance_key.save!
      self.save!
    end
  end

  def self.get_user_instances_stats(user)
    stats = {
      :running_instances => 0,
      :stopped_instances => 0,
    }

    instances = []
    pools = Pool.list_for_user(user, Privilege::VIEW, Instance)
    pools.each{|pool| pool.instances.each {|i| instances << i}}
    instances.each do |i|
      if i.state == Instance::STATE_RUNNING
        stats[:running_instances] += 1
      elsif i.state == Instance::STATE_STOPPED
        stats[:stopped_instances] += 1
      end
    end
    stats[:total_instances] = instances.size
    return stats
  end

  def restartable?
    # TODO: we don't support stateful instances yet, so it's `false` for the time being.
    # In the meantime, we can use this method to write validation code for cases
    # where does matter whether an instance is stateful or stateless.
    false
  end

  def destroyable?
    (state == STATE_CREATE_FAILED) or (state == STATE_STOPPED and not restartable?)
  end

  named_scope :with_hardware_profile, lambda {
      {:include => :hardware_profile}
  }
end
