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
#  uuid                   :text            not null
#

require 'util/deployable_xml'
require 'util/config_server_util'

class Deployment < ActiveRecord::Base
  include PermissionedObject
  class << self
    include CommonFilterMethods
  end

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
  before_create :inject_launch_parameters
  before_create :generate_uuid

  USER_MUTABLE_ATTRS = ['name']
  STATE_MIXED = "mixed"

  validate :validate_xml
  validate :validate_launch_parameters

  def validate_xml
    begin
      deployable_xml.validate!
    rescue DeployableXML::ValidationError => e
      errors.add(:deployable_xml, e.message)
    end
  end

  def validate_launch_parameters
    launch_parameters.each do |asm, services|
      services.each do |service, params|
        params.each do |param, value|
          if value.blank?
            errors.add(:launch_parameters, "#{asm}.#{service}.#{param} cannot be blank")
          end
        end
      end
  end
  end

  def pool_must_be_enabled
    errors.add(:pool, I18n.t('pools.errors.must_be_enabled')) unless pool and pool.enabled?
    errors.add(:pool, I18n.t('pools.errors.providers_disabled')) if pool and pool.pool_family.all_providers_disabled?
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
      destroy_deployment_config
      destroy
      return
    end

    if instances.all? {|i| i.destroyable? or i.state == Instance::STATE_RUNNING}
      destroy_deployment_config
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

  def launch_parameters
    @launch_parameters ||= {}
  end

  def launch_parameters=(launch_parameters)
    @launch_parameters = launch_parameters
  end

  def launch(user, config_values = nil)
    # first, create all the instance objects,
    # if a config server is being used
    #     find if there is at least a single account where they can all launch,
    # then generate the instance configs for the instances,
    # if a using a config server
    #     then, for each instance send the instance configs to the config server,
    # and launch the instances
    #
    # TODO: need to be able to handle deployable-level errors
    #
    status = { :errors => {}, :successes => {} }
    assembly_instances = {}
    deployable_xml.assemblies.each do |assembly|
      # TODO: for now we try to start all instances even if some of them fails
      begin
        task = nil
        Instance.transaction do
          hw_profile = permissioned_frontend_hwprofile(user, assembly.hwp)
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
          # store the assembly's parameters
          assembly.services.each do |service|
            service.parameters.each do |parameter|
              if not parameter.reference?
                param = InstanceParameter.create!(
                  :instance => instance,
                  :service => service.name,
                  :name => parameter.name,
                  :type => parameter.type,
                  :value => parameter.value
                )
              end
            end
          end

          assembly_instances[assembly.name] = instance
        end
      rescue
        logger.error $!.message
        logger.error $!.backtrace.join("\n    ")
        status[:errors][assembly.name] = $!.message
      end
    end
    # figure out which config server to use
    # and, generate the instance configurations for the instances
    if deployable_xml.requires_config_server?
      matches, errors = Instance.matches(assembly_instances.values)
      if matches.empty?
        #TODO:need to have a way to show the errors in a meaningful way
        status[:errors][name] = errors
        return status
      end
      found = matches.first
      config_server = found.provider_account.config_server
      instance_configs = ConfigServerUtil.instance_configs(self, assembly_instances.values, config_server)
    end
    # now actually do the launch
    assembly_instances.each do |assembly_name, instance|
      config = instance_configs[instance.uuid] if deployable_xml.requires_config_server?
      begin
        if deployable_xml.requires_config_server?
          instance.user_data = Instance.generate_user_data(instance, config_server)
          instance.instance_config_xml = config.to_s
          instance.save!
        end

        task = InstanceTask.create!({:user        => user,
                                     :task_target => instance,
                                     :action      => InstanceTask::ACTION_CREATE})
        if deployable_xml.requires_config_server?
          begin
            config_server.send_config(config)
          rescue Errno::ECONNREFUSED
            raise I18n.t 'deployments.errors.config_server_connection'
          end
        end
        Taskomatic.create_instance(task)
        if task.state == Task::STATE_FAILED
          status[:errors][assembly_name] = 'failed'
        else
          status[:successes][assembly_name] = 'launched'
        end
      rescue
        logger.error $!.message
        logger.error $!.backtrace.join("\n    ")
        status[:errors][assembly_name] = $!.message
      end
    end
    status
  end

  def self.list(order_field, order_dir)
    Deployment.all(:include => :owner,
                   :order => (order_field || 'name') +' '+ (order_dir || 'asc'))
  end

  def valid_deployable_xml?(xml)
    begin
      self.deployable_xml = DeployableXML.new(xml)
      deployable_xml.validate!
      true
    rescue
      errors.add(:base, I18n.t("deployments.errors.not_valid_deployable_xml", :msg => "#{$!.message}"))
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
        hw_profile = permissioned_frontend_hwprofile(user, assembly.hwp)
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

  # A deployment "starts" when _all_ instances begin to run
  def start_time
    if instances.deployed.count == instances.count && ev = events.find_by_status_code(:all_running)
      ev.event_time
    else
      nil
    end
  end

  # A deployment "ends" when one or more instances stop, assuming they were ever all-running
  def end_time
    if events.find_by_status_code(:all_running)
      ev = events.find_by_status_code(:some_stopped) || events.find_by_status_code(:all_stopped)
      ev.present? ? ev.event_time : nil
    else
      nil
    end
  end

  def as_json(options={})
    json = super(options).merge({
      :owner => owner.name,
      :deployable_xml_name => deployable_xml.name,
      :deployment_state => deployment_state,
      :instances_count => instances.count,
      :uptime => ApplicationHelper.count_uptime(uptime_1st_instance),
      :pool => {
        :name => pool.name,
        :id => pool.id,
      },
    })

    if provider
      json[:provider] = {
        :name => provider.provider_type.name,
        :id => provider.id,
      }
    end

    json
  end

  def deployment_state
    unless instances.empty?
      return instances.first.state if not instances.empty? and instances.length == 1
      oracle = instances.first.state
      instances.each do |i|
        return STATE_MIXED if i.state != oracle
      end
      return oracle
    else
      return
    end
  end

  PRESET_FILTERS_OPTIONS = []

  private

  def self.apply_search_filter(search)
    if search
      includes(:pool).where("pools.name ILIKE :search OR deployments.deployable_xml ILIKE :search OR deployments.name ILIKE :search", :search => "%#{search}%")
    else
      scoped
    end
  end

  def permissioned_frontend_hwprofile(user, hwp_name)
    HardwareProfile.list_for_user(user, Privilege::VIEW).where('hardware_profiles.name = :name AND provider_id IS NULL', {:name => hwp_name}).first
  end

  def inject_launch_parameters
    launch_parameters.each_pair do |assembly, svcs|
      svcs.each_pair do |service, params|
        params.each_pair do |param, value|
          deployable_xml.set_parameter_value(assembly, service, param, value)
        end
      end
    end
  end

  def destroy_deployment_config
    # the implication here is that if there is an instance in this deployment
    # with userdata, then a config server was associated with this deployment;
    # further, the config server associated with one instance is the same config
    # server used for all instances in the deployment
    # this logic could easily change
    if instances.any? {|instance| instance.user_data}
      configserver = instances.first.provider_account.config_server
      configserver.delete_deployment_config(uuid) if configserver
    end
  end

  def generate_uuid
    self[:uuid] = UUIDTools::UUID.timestamp_create.to_s
  end
end
