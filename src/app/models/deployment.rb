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

# == Schema Information
#
# Table name: deployments
#
#  id                     :integer         not null, primary key
#  name                   :string(1024)    not null
#  realm_id               :integer
#  owner_id               :integer
#  pool_id                :integer         not null
#  lock_version           :integer         default(0)
#  created_at             :datetime
#  updated_at             :datetime
#  frontend_realm_id      :integer
#  deployable_xml         :text
#  scheduled_for_deletion :boolean         default(FALSE), not null
#

require 'util/deployable_xml'

class Deployment < ActiveRecord::Base
  include PermissionedObject

  belongs_to :pool

  has_many :instances, :dependent => :destroy

  belongs_to :realm
  belongs_to :frontend_realm

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"

  has_many :events, :as => :source

  after_create "assign_owner_roles(owner)"

  validates_presence_of :pool_id

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :pool_id
  validates_length_of :name, :maximum => 1024
  validates_presence_of :owner_id
  validate :pool_must_be_enabled

  before_destroy :destroyable?

  SEARCHABLE_COLUMNS = %w(name)

  USER_MUTABLE_ATTRS = ['name']

  validate :validate_xml

  def validate_xml
    begin
      deployable_xml.validate!
    rescue DeployableXML::ValidationError => e
      errors.add(:deployable_xml, e.message)
    end
  end

  def pool_must_be_enabled
    errors.add(:pool, "must be enabled") unless pool and pool.enabled?
  end

  def object_list
    super << pool
  end
  class << self
    alias orig_list_for_user_include list_for_user_include
    alias orig_list_for_user_conditions list_for_user_conditions
  end

  def self.list_for_user_include
    includes = orig_list_for_user_include
    includes << { :pool => {:permissions => {:role => :privileges}}}
    includes
  end

  def self.list_for_user_conditions
    "(#{orig_list_for_user_conditions}) or
     (permissions_pools.user_id=:user and
      privileges_roles.target_type=:target_type and
      privileges_roles.action=:action)"
  end

  def get_action_list(user=nil)
    # FIXME: how do actions and states interact for deployments?
    # For instances the list comes from the provider based on current state.
    # Deployments don't currently have an explicit state field, but
    # something could be calculated from associated instances.
    ["start", "stop", "reboot"]
  end

  def valid_action?(action)
    return get_action_list.include?(action) ? true : false
  end

  def destroyable?
    instances.all? {|i| i.destroyable? }
  end

  def stop_instances_and_destroy!
    if destroyable?
      destroy
      return
    end

    if instances.all? {|i| i.destroyable? or i.state == Instance::STATE_RUNNING}
      # The deployment will be destroyed from an InstanceObserver callback once
      # all instances are stopped.
      self.scheduled_for_deletion = true
      self.save!

      # stop all deployment's instances
      instances.each do |instance|
        break unless instance.state == Instance::STATE_RUNNING

        @task = instance.queue_action(instance.owner, 'stop')
        unless @task
          raise ActionError.new("stop cannot be performed on this instance.")
        end
        Taskomatic.stop_instance(@task)
      end
    else
      raise ActionError.new 'all instances must be stopped or running'
    end
  end

  def launch(user)
    status = { :errors => {}, :successes => {} }
    deployable_xml.assemblies.each do |assembly|
      # TODO: for now we try to start all instances even if some of them fails
      begin
        task = nil
        Instance.transaction do
          hw_profile = HardwareProfile.frontend.find_by_name(assembly.hwp)
          raise "Hardware Profile #{assembly.hwp} not found." unless hw_profile
          instance = Instance.create!(
            :deployment => self,
            :name => "#{name}/#{assembly.name}",
            :frontend_realm => frontend_realm,
            :pool => pool,
            :image_uuid => assembly.image_id,
            :image_build_uuid => assembly.image_build,
            :assembly_xml => assembly.to_s,
            :state => Instance::STATE_NEW,
            :owner => user,
            :hardware_profile => hw_profile
          )
          task = InstanceTask.create!({:user        => user,
                                       :task_target => instance,
                                       :action      => InstanceTask::ACTION_CREATE})
        end
        Taskomatic.create_instance(task)
        if task.state == Task::STATE_FAILED
          status[:errors][assembly.name] = 'failed'
        else
          status[:successes][assembly.name] = 'launched'
        end
      rescue
        logger.error $!.message
        logger.error $!.backtrace.join("\n    ")
        status[:errors][assembly.name] = $!.message
      end
    end
    status
  end

  def self.list(order_field, order_dir)
    Deployment.all(:include => :owner,
                   :order => (order_field || 'name') +' '+ (order_dir || 'asc'))
  end

  def accessible_and_valid_deployable_xml?(url)
    begin
      self.deployable_xml = DeployableXML.import_xml_from_url(url)
      deployable_xml.validate!
      true
    rescue
      errors.add(:base, "failed to get the deployable definition: #{$!.message}")
      false
    end
  end

  def deployable_xml
    @deployable_xml ||= DeployableXML.new(self[:deployable_xml].to_s)
  end

  def properties
    {:name => name, :owner => "#{owner.first_name}  #{owner.last_name}", :created => created_at, :pool => pool.name}
  end

  def provider
    # I REALLY want to get this via a join, but no dice...
    instances.first.provider_account.provider rescue nil
  end

  # we try to create an instance for each assembly and check
  # if a match is found
  def check_assemblies_matches(user)
    errs = {}
    deployable_xml.assemblies.each do |assembly|
      begin
        hw_profile = HardwareProfile.frontend.find_by_name(assembly.hwp)
        raise "Hardware Profile #{assembly.hwp} not found." unless hw_profile
        instance = Instance.new(
          :deployment => self,
          :name => "#{name}/#{assembly.name}",
          :frontend_realm => frontend_realm,
          :pool => pool,
          :image_uuid => assembly.image_id,
          :image_build_uuid => assembly.image_build,
          :assembly_xml => assembly.to_s,
          :state => Instance::STATE_NEW,
          :owner => user,
          :hardware_profile => hw_profile
        )
        possibles, errors = instance.matches
        if possibles.empty? and not errors.empty?
          raise errors.join(", ")
        end
      rescue
        errs[assembly.name] = $!.message
      end
    end
    errs
  end

  def all_instances_running?
    instances.deployed.count == instances.count
  end

  def any_instance_running?
    instances.any? {|i| i.state == Instance::STATE_RUNNING }
  end

  def uptime_1st_instance
    return if events.empty?
    if instances.deployed.empty?
      if instances.count > 1 && events.find_by_status_code(:all_stopped) && events.find_by_status_code(:first_running)
        events.find_by_status_code(:all_stopped).event_time - events.find_by_status_code(:first_running).event_time
      elsif events.find_by_status_code(:all_stopped) && events.find_by_status_code(:all_running)
        events.find_by_status_code(:all_stopped).event_time - events.find_by_status_code(:all_running).event_time
      end
    else
      if instances.count > 1 && events.find_by_status_code(:first_running)
        Time.now.utc - events.find_by_status_code(:first_running).event_time
      elsif events.find_by_status_code(:all_running)
        Time.now.utc - events.find_by_status_code(:all_running).event_time
      end
    end
  end

  def uptime_all
    return if events.empty?
    if instances.deployed.count == instances.count && events.find_by_status_code(:all_running)
      Time.now.utc - events.lifetime.last.event_time
    elsif instances.count > 1 && events.find_by_status_code(:all_running) && events.find_by_status_code(:some_stopped)
      events.find_by_status_code(:some_stopped).event_time - events.find_by_status_code(:all_running).event_time
    elsif events.find_by_status_code(:all_stopped) && events.find_by_status_code(:all_running)
      events.find_by_status_code(:all_stopped).event_time - events.find_by_status_code(:all_running).event_time
    end
  end

  def as_json(options={})
    json = super(options).merge({
      :owner => owner.name,
      :deployable_xml_name => deployable_xml.name,
      :instances_count => instances.count,
      :uptime => ApplicationHelper.count_uptime(uptime_1st_instance),
      :href => Rails.application.routes.url_helpers.deployment_path(id),
      :pool => {
        :name => pool.name,
        :href => Rails.application.routes.url_helpers.pool_path(pool.id),
      },
    })

    if provider
      json[:provider] = {
        :name => provider.provider_type.name,
        :href => Rails.application.routes.url_helpers.provider_path(provider.id),
      }
    end

    json
  end
end
