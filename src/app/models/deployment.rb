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

  has_many :provider_accounts, :through => :instances

  after_create "assign_owner_roles(owner)"

  scope :ascending_by_name, :order => 'deployments.name ASC'

  validates_presence_of :pool_id
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :pool_id
  validates_length_of :name, :maximum => 50
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
    rescue Nokogiri::XML::SyntaxError => e
      errors.add(:base, I18n.t("deployments.errors.not_valid_deployable_xml", :msg => "#{e.message}"))
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
        next unless instance.state == Instance::STATE_RUNNING

        @task = instance.queue_action(instance.owner, 'stop')
        unless @task
          raise I18n.t("deployments.errors.cannot_stop")
        end
        Taskomatic.stop_instance(@task)
      end
    else
      raise I18n.t("deployments.errors.all_stopped")
    end
  end

  def self.stoppable_inaccessible_instances(deployments)
    failed_accounts = {}
    res = []
    deployments.each do |d|
      next unless acc = d.provider_account
      failed_accounts[acc.id] = acc.connect.nil? unless failed_accounts.has_key?(acc.id)
      next unless failed_accounts[acc.id]
      res += d.instances.stoppable_inaccessible
    end
    res
  end

  def launch_parameters
    @launch_parameters ||= {}
  end

  def launch_parameters=(launch_parameters)
    @launch_parameters = launch_parameters
  end

  def launch(user)
    # first, create the instance and instance_parameter objects
    # then, find a single provider account where all instances can launch
    # then, if a config server is being used
    #   then generate the instance configs for each instance,
    #   then send the instance configs to the config server,
    # finally, launch the instances
    #
    # TODO: need to be able to handle deployable-level errors
    #
    status = { :errors => {}, :successes => {} }
    assembly_instances = {}
    deployable_xml.assemblies.each do |assembly|
      begin
        hw_profile = permissioned_frontend_hwprofile(user, assembly.hwp)
        raise "Hardware Profile #{assembly.hwp} not found." unless hw_profile
        Instance.transaction do
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
        status[:errors][assembly.name] = $!.message.to_s.split("\n").first
      end
    end

    account_matches, errors = common_provider_accounts_for(assembly_instances.values)
    if account_matches.empty?
      status[:errors][name] = errors
      return status
    end
    # grab the account with the best priority that can launch this deployment
    account = account_matches.keys.sort do |a,b|
      if a.priority.nil? and b.priority.nil?
        0
      elsif a.priority.nil?
        1
      elsif b.priority.nil?
        -1
      else
        a.priority <=> b.priority
      end
    end.first
    instances_matches = account_matches[account]

    if deployable_xml.requires_config_server?
      # the instance configurations need to be generated from the entire set of
      # instances (and not each individual instance) in order to do parameter
      # dependency resolution across the set
      config_server = account.config_server
      instance_configs = ConfigServerUtil.instance_configs(self, assembly_instances.values, config_server)
    end

    assembly_instances.each do |assembly_name, instance|
      match = instances_matches[instance]
      config = instance_configs[instance.uuid] if deployable_xml.requires_config_server?
      begin
        if deployable_xml.requires_config_server?
          instance.user_data = Instance.generate_user_data(instance, config_server)
          instance.instance_config_xml = config.to_s
          instance.save!
        end
        # create a taskomatic task
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
        Taskomatic.create_instance(task, match)
        if task.state == Task::STATE_FAILED
          status[:errors][assembly_name] = 'failed'
        else
          status[:successes][assembly_name] = 'launched'
        end
      rescue
        logger.error $!.message
        logger.error $!.backtrace.join("\n    ")
        status[:errors][assembly_name] = $!.message.to_s.split("\n").first
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
    result = {
      :name => name,
      :created => created_at,
      :pool => pool.name
    }

    result[:owner] = "#{owner.first_name}  #{owner.last_name}" if owner.present?

    result
  end

  def provider
    inst = instances.joins(:provider_account => :provider).first
    inst && inst.provider_account && inst.provider_account.provider
  end

  def provider_account
    inst = instances.joins(:provider_account).first
    inst && inst.provider_account
  end

  # we try to create an instance for each assembly and check
  # if a match is found
  def check_assemblies_matches(user)
    errs = []
    instances = []
    begin
      deployable_xml.assemblies.each do |assembly|
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
        instances << instance
        possibles, errors = instance.matches
        if possibles.empty? and not errors.empty?
          raise Aeolus::Conductor::MultiError::UnlaunchableAssembly.new(I18n.t('deployments.flash.error.not_launched'), errors)
        end
      end

      deployment_errors = []
      deployment_errors << I18n.t('instances.errors.pool_quota_reached') if not pool.quota.can_start?(instances)
      deployment_errors << I18n.t('instances.errors.pool_family_quota_reached') if not pool.pool_family.quota.can_start?(instances)
      if not deployment_errors.empty?
        raise Aeolus::Conductor::MultiError::UnlaunchableAssembly.new(I18n.t('deployments.flash.error.not_launched'), deployment_errors)
      end
    rescue
      errs = $!.message
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
    return nil if events.empty?

    first_running = events.find_by_status_code(:first_running)
    if instances.deployed.empty?
      all_stopped = events.find_last_by_status_code(:all_stopped)
      if all_stopped && first_running && all_stopped.event_time > first_running.event_time
        all_stopped.event_time - first_running.event_time
      else
        nil
      end
    else
      if first_running
        Time.now.utc - first_running.event_time
      else
        nil
      end
    end
  end

  def uptime_all
    return nil if events.empty?

    all_running = events.find_last_by_status_code(:all_running)
    some_stopped = events.find_last_by_status_code(:some_stopped)
    all_stopped = events.find_last_by_status_code(:all_stopped)

    if instances.deployed.count == instances.count && all_running
      Time.now.utc - all_running.event_time
    elsif instances.count > 1 && all_running && some_stopped
      some_stopped.event_time - all_running.event_time
    elsif all_stopped && all_running && all_stopped.event_time > all_running.event_time
      all_stopped.event_time - all_running.event_time
    else
      nil
    end
  end

  def status
    if instances.any? and instances.all? {|i| i.state == Instance::STATE_RUNNING}
      :running
    elsif instances.empty? or instances.all? {|i| (Instance::FAILED_STATES + [Instance::STATE_STOPPED]).include?(i.state)}
      :stopped
    else
      :pending
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
      :deployable_xml_name => deployable_xml.name,
      :status => status,
      :status_description => I18n.t("deployments.status.#{status}"),
      :instances_count => instances.count,
      :failed_instances_count => failed_instances.count,
      :instances_count_text => I18n.t('instances.instances', :count => instances.count.to_i),
      :uptime => ApplicationHelper.count_uptime(uptime_1st_instance),
      :pool => {
        :name => pool.name,
        :id => pool.id,
      },
      :created_at => created_at.to_s
    })

    json[:owner] = owner.name if owner.present?

    if provider
      json[:provider] = {
        :name => provider.provider_type.name,
        :id => provider.id,
      }
    end

    json
  end

  def failed_instances
    instances.select {|instance| instance.failed?}
  end

  PRESET_FILTERS_OPTIONS = []

  private

  def self.apply_search_filter(search)
    # TODO: after upgrading to 3.1 the SQL join statement can be done in Rails way by adding a has_many association to providers through provider_accounts
    #       (Rails before version 3.1 does not support nested associations with through param)
    if search
      includes(:pool, :provider_accounts => :provider).
          joins("LEFT OUTER JOIN provider_types ON provider_types.id = providers.provider_type_id").
          where("lower(pools.name) LIKE :search OR lower(deployments.name) LIKE :search OR lower(provider_types.name) LIKE :search",
                :search => "%#{search.downcase}%")
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
      # guard against the provider_account being nil
      if instances.first.provider_account
        configserver = instances.first.provider_account.config_server
        configserver.delete_deployment_config(uuid) if configserver
      end
    end
  end

  # Find the provider accounts where all the given instances can be launched
  # Returns a tuple of the form:
  #   [{account => {instance => match, instance => match},
  #     account => {instance => match, instance => match}},
  #    errors]
  def common_provider_accounts_for(instances)
    matches = nil
    errors = []
    instance_matches = {}
    instances.each do |instance|
      m, e = instance.matches
      instance_matches[instance] = m if m and not m.empty?
      errors << e
    end
    # this series of map-reductions takes the input:
    #   instance_matches
    #     {i1 => [m1, m2, m3], i2 => [m4, m5, m6]}
    # and translates it into the form:
    #     {a1 => {i1 => m1, i2 => m4},
    #      a2 => {i1 => m2, i2 => m5},
    #      a3 => {i1 => m3, i2 => m6}}
    # where iN is an instance, mN is a match, and aN is an account
    account_matches = instance_matches.map do |instance, matches|
      matches.map do |match|
        {match.provider_account => {instance => match}}
      end.reduce :merge
    end.reduce do |account_map, instance_map|
      account_map.merge!(instance_map) do |key, v1, v2|
        v1.merge(v2)
      end
    end || []

    # reject any accounts that cannot launch the entire deployment
    account_matches.reject! do |account, instance_map|
      # implies that one or more instance does not have a corresponding image
      # pushed to this account
      rejected = instance_map.size < instances.size

      # also check that the account's quota can handle all the instances
      if not rejected
        if not account.quota.can_start? instances
          errors << I18n.t('instances.errors.provider_account_quota_too_low', :match_provider_account => account)
          rejected = true
        end
      end
      rejected
    end if not account_matches.empty?

    [account_matches, errors]
  end

  def generate_uuid
    self[:uuid] = UUIDTools::UUID.timestamp_create.to_s
  end
end
