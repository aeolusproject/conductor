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
  acts_as_paranoid

  include PermissionedObject
  class << self
    include CommonFilterMethods
  end

  before_destroy :destroyable?

  belongs_to :pool
  belongs_to :pool_family

  has_many :instances, :dependent => :destroy

  belongs_to :provider_realm
  belongs_to :frontend_realm

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"

  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"

  has_many :events, :as => :source, :dependent => :destroy,
           :order => 'events.id ASC'

  has_many :provider_accounts, :through => :instances

  after_create "assign_owner_roles(owner)"

  scope :ascending_by_name, :order => 'deployments.name ASC'

  before_validation :replace_special_characters_in_name
  validates_presence_of :pool_id
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:pool_id, :deleted_at]
  validates_length_of :name, :maximum => 50
  validates_presence_of :owner_id
  validate :pool_must_be_enabled, :on => :create
  before_destroy :destroy_deployment_config
  before_create :inject_launch_parameters
  before_create :generate_uuid
  before_create :set_pool_family
  before_create :set_new_state
  after_save :log_state_change
  after_save :handle_completed_rollback

  USER_MUTABLE_ATTRS = ['name']

  STATE_NEW                  = "new"
  STATE_PENDING              = "pending"
  STATE_RUNNING              = "running"
  STATE_INCOMPLETE           = "incomplete"
  STATE_SHUTTING_DOWN        = "shutting_down"
  STATE_STOPPED              = "stopped"
  STATE_FAILED               = "failed"
  STATE_ROLLBACK_IN_PROGRESS = "rollback_in_progress"
  STATE_ROLLBACK_COMPLETE    = "rollback_complete"
  STATE_ROLLBACK_FAILED      = "rollback_failed"

  STATES = [STATE_NEW, STATE_PENDING, STATE_RUNNING, STATE_INCOMPLETE,
            STATE_SHUTTING_DOWN, STATE_STOPPED, STATE_FAILED,
            STATE_ROLLBACK_IN_PROGRESS, STATE_ROLLBACK_COMPLETE,
            STATE_ROLLBACK_FAILED]
  # list of states in which it's possible to start single instance
  INSTANCE_STARTABLE_STATES = [STATE_NEW, STATE_PENDING, STATE_RUNNING,
                               STATE_INCOMPLETE, STATE_SHUTTING_DOWN,
                               STATE_STOPPED]

  validate :validate_xml
  validate :validate_launch_parameters

  def validate_xml
    begin
      deployable_xml.validate!
    rescue DeployableXML::ValidationError => e
      errors.add(:deployable_xml, e.message)
    rescue Nokogiri::XML::SyntaxError => e
      errors.add(:base, _("seems to be not valid Deployable XML: %s") % e.message)
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
    errors.add(:pool, _("must be enabled")) unless pool and pool.enabled?
    errors.add(:pool, _("has all associated Providers disabled")) if pool and pool.pool_family.all_providers_disabled?
  end

  def perm_ancestors
    super + [pool, pool_family]
  end
  def derived_subtree(role = nil)
    subtree = super(role)
    subtree += instances if (role.nil? or role.privilege_target_match(Instance))
    subtree
  end
  def self.additional_privilege_target_types
    [Instance]
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

  def can_stop?
    [STATE_RUNNING, STATE_INCOMPLETE].include?(self.state)
  end

  def not_stoppable_or_destroyable_instances
    instances.find_all {|i| !(i.destroyable? or
                              i.state == Instance::STATE_RUNNING)}
  end

  def stop_instances_and_destroy!
    if destroyable?
      destroy!
    else
      self.state = Deployment::STATE_SHUTTING_DOWN
      # The deployment will be destroyed from an InstanceObserver callback once
      # all instances are stopped.
      self.scheduled_for_deletion = true
      self.save!

      # stop all deployment's instances
      instances.running.each {|instance| instance.stop(instance.owner)}
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

  def create_and_launch(permission_session, user)
    begin
      # this method doesn't restore record state if this transaction
      # fails, wrapping transaction in rollback_active_record_state!
      # is not sufficient because restore then doesn't work if
      # you have some nested save operations inside the transaction
      transaction do
        save!
        create_instances_with_params!(permission_session, user)
        launch!(user)
      end
      return true
    rescue
      errors.add(:base, $!.message)
      log_backtrace($!)
    end
    false
  end

  def launch!(user)
    self.reload unless self.new_record?
    self.state = STATE_PENDING
    save!

    all_inst_match, account, errs = pick_provider_selection_match

    if all_inst_match
      self.events << Event.create(
        :source => self,
        :event_time => DateTime.now,
        :status_code => 'deployment_launch_match',
        :summary => _("Attempting to launch this deployment on provider account %s") % account.name
      )
    else
      if errs.any?
        raise _("Match not found: %s") % errs.join(", ")
      else
        raise _("Unable to find a suitable Provider Account to host the Deployment. Check the quota of the Provider Accounts and the status of the Images.")
      end
    end

    # Array of InstanceMatches returned by pick_provider_selection_match
    # is converted to hashes because if we use directly instance of
    # InstanceMatch model, delayed job tries to load this object from DB
    all_inst_match.map!{|m| m.attributes}

    if deployable_xml.requires_config_server?
      config_server_id = account.config_server.id
    else
      config_server_id = nil
    end

    delay.send_launch_requests(all_inst_match,
                               instances.map{|i| i.id},
                               config_server_id, user.id)
  end

  def send_launch_requests(all_inst_match, instance_ids, config_server_id, user_id)
    user = User.find(user_id)
    instances = instance_ids.map{|instance_id| Instance.find(instance_id)}

    if config_server_id.nil?
      config_server = nil
      instance_configs = {}
    else
      config_server = ConfigServer.find(config_server_id)

      # the instance configurations need to be generated from the entire set of
      # instances (and not each individual instance) in order to do parameter
      # dependency resolution across the set
      instance_configs = ConfigServerUtil.instance_configs(self,instances,config_server)
    end

    instances.each do |instance|
      instance.reset_attrs unless instance.state == Instance::STATE_NEW
      instance.instance_matches << InstanceMatch.new(
        all_inst_match.find{|m| m['instance_id'] == instance.id})
      begin
        instance.launch!(instance.instance_matches.last,
                         user,
                         config_server,
                         instance_configs[instance.uuid])
      rescue
        # be default launching of instances is terminated if an error occurs,
        # user can set "partial_launch" attribute - launch request is then
        # sent for all deployment's instances
        break unless partial_launch
      end
    end
    true
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
      errors.add(:base, _("seems to be not valid Deployable XML: %s") % $!.message )
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
    if deleted?
      inst = instances.unscoped.joins(:provider_account => :provider).first
    else
      inst = instances.joins(:provider_account => :provider).first
    end
    inst && inst.provider_account && inst.provider_account.provider
  end

  def provider_account
    if deleted?
      inst = instances.unscoped.joins(:provider_account).first
    else
      inst = instances.joins(:provider_account).first
    end
    inst && inst.provider_account
  end

  # we try to create an instance for each assembly and check
  # if a match is found
  def check_assemblies_matches(permission_session, user)
    errs = []
    begin
      deployable_xml.assemblies.each do |assembly|
        hw_profile = permissioned_frontend_hwprofile(permission_session,
                                                     user, assembly.hwp)
        raise _("You do not have sufficient permission to access the %s Hardware Profile.") % assembly.hwp unless hw_profile
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
          raise Aeolus::Conductor::MultiError::UnlaunchableAssembly.new(_("Some Assemblies will not be launched:"), errors)
        end
      end

      deployment_errors = []

      unless provider_selection_match_exists?
        deployment_errors << _("Unable to find a suitable Provider Account to host the Deployment. Check the quota of the Provider Accounts and the status of the Images.")
      end

      unless pool.quota.can_start?(instances)
        deployment_errors << _("Pool quota reached")
      end

      unless pool.pool_family.quota.can_start?(instances)
        deployment_errors << _("Environment quota reached")
      end

      unless user.quota.can_start?(instances)
        deployment_errors << _("User quota reached")
      end

      if deployment_errors.any?
        raise Aeolus::Conductor::MultiError::UnlaunchableAssembly.new(_("Some Assemblies will not be launched:"), deployment_errors)
      end
    rescue
      errs << $!.message
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

    first_running = events.find_last_by_status_code(:first_running)
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

  # A deployment "starts" when _all_ instances begin to run
  def start_time
    if instances.deployed.count == instances.count && ev = events.find_last_by_status_code(:all_running)
      ev.event_time
    else
      nil
    end
  end

  # A deployment "ends" when one or more instances stop, assuming they were ever all-running
  def end_time
    if events.find_last_by_status_code(:all_running)
      ev = events.find_last_by_status_code(:some_stopped) || events.find_last_by_status_code(:all_stopped)
      ev.present? ? ev.event_time : nil
    else
      nil
    end
  end

  def as_json(options={})
    json = super(options).merge({
      :deployable_xml_name => deployable_xml.name,
      :status => state,
      :translated_state => _(state),
      :status_description => state_description,
      :instances_count => instances.count,
      :failed_instances_count => failed_instances.count,
      :instances_count_text => n_("Instance","Instances",instances.count),
      :uptime => ApplicationHelper.count_uptime(uptime_1st_instance),
      :pool => {
        :name => pool.name,
        :id => pool.id,
      },
      :created_at => created_at.to_s
    })

    json[:owner] = owner.name if owner.present?

    deployment_provider = provider
    if deployment_provider
      json[:provider] = {
        :name => deployment_provider.provider_type.name,
        :id => deployment_provider.id,
      }
    end

    json
  end

  def failed_instances
    instances.failed
  end

  def update_state(changed_instance)
    transition_method = "state_transition_from_#{state}".to_sym
    send(transition_method, changed_instance) if self.respond_to?(transition_method, true)
    if state_changed?
      save!
      true
    else
      false
    end
  end

  def copy_as_new
    d = Deployment.new(self.attributes)
    d.errors.merge!(self.errors)
    d
  end

  def events_of_deployment_and_instances
    instance_ids = instances.map(&:id)
    Event.all(:conditions => ["(source_type='Instance' AND source_id in (?))"\
                              "OR (source_type='Deployment' AND source_id=?)",
                              instance_ids, self.id],
              :order => "created_at ASC")

  end

  def state_description
    case state
      when STATE_NEW
        _("Deployment wasn't started")
      when STATE_PENDING
        _("Deployment is starting up")
      when STATE_RUNNING
        _("All Instances are running")
      when STATE_INCOMPLETE
        _("Some Instances are not running")
      when STATE_SHUTTING_DOWN
        _("Deployment is shutting down")
      when STATE_STOPPED
        _("All Instances are stopped")
      when STATE_FAILED
        _("All Instances are in failed state")
      when STATE_ROLLBACK_IN_PROGRESS
        _("Launch failed, rollback is in progress")
      when STATE_ROLLBACK_COMPLETE
        _("Rollback successfully completed")
      when STATE_ROLLBACK_FAILED
        _("Rollback failed, re-launch terminated")
    end
  end

  PRESET_FILTERS_OPTIONS = [
    {:title => "deployments.preset_filters.other_than_stopped", :id => "other_than_stopped", :query => where("deployments.state != ?", "stopped")},
    {:title => "deployments.preset_filters.new", :id => "new", :query => where("deployments.state" => "new")},
    {:title => "deployments.preset_filters.pending", :id => "pending", :query => where("deployments.state" => "pending")},
    {:title => "deployments.preset_filters.running", :id => "running", :query => where("deployments.state" => "running")},
    {:title => "deployments.preset_filters.incomplete", :id => "incomplete", :query => where("deployments.state" => "incomplete")},
    {:title => "deployments.preset_filters.shutting_down", :id => "shutting_down", :query => where("deployments.state" => "shutting_down")},
    {:title => "deployments.preset_filters.stopped", :id => "stopped", :query => where("deployments.state" => "stopped")},
    {:title => "deployments.preset_filters.failed", :id => "failed", :query => where("deployments.state" => "failed")},
    {:title => "deployments.preset_filters.rollback_failed", :id => "rollback_failed", :query => where("deployments.state" => "rollback_failed")}
  ]

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

  def permissioned_frontend_hwprofile(permission_session, user, hwp_name)
    HardwareProfile.list_for_user(permission_session, user, Privilege::VIEW).where('hardware_profiles.name = :name AND provider_id IS NULL', {:name => hwp_name}).first
  end

  def inject_launch_parameters
    launch_parameters.each_pair do |assembly, svcs|
      svcs.each_pair do |service, params|
        params.each_pair do |param, value|
          deployable_xml.set_parameter_value(assembly, service, param, value)
        end
      end
    end
    self.deployable_xml = deployable_xml.to_s
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

  def init_provider_selection
    provider_selection = ProviderSelection::Base.new(instances)
    pool.provider_selection_strategies.enabled.each do |strategy|
      provider_selection.chain_strategy(strategy.name, strategy.config)
    end
    provider_selection
  end

  def provider_selection_match_exists?
    init_provider_selection.match_exists?
  end

  def pick_provider_selection_match
    provider_selection = init_provider_selection
    match = provider_selection.next_match

    return_error = proc { return [nil, nil, provider_selection.errors] }
    return_error.call unless match.present?

    all_matches = instances.map { |instance| instance.matches[0] }
    provider_account = match.provider_account
    matches_by_account = all_matches.map do |matches|
      matches.find { |m| m.provider_account.id == provider_account.id }
    end

    return_error.call if matches_by_account.include?(nil)
    [matches_by_account, provider_account, provider_selection.errors]
  end

  def generate_uuid
    self[:uuid] = UUIDTools::UUID.timestamp_create.to_s
  end

  def replace_special_characters_in_name
    name.gsub!(/[^a-zA-Z0-9]+/, '-') if !name.nil?
  end

  def set_pool_family
    self[:pool_family_id] = pool.pool_family_id
  end

  def create_instances_with_params!(permission_session, user)
    errors = {}
    deployable_xml.assemblies.each do |assembly|
      hw_profile = permissioned_frontend_hwprofile(permission_session,
                                                   user, assembly.hwp)
      raise _("You do not have sufficient permission to access the %s Hardware Profile.") % assembly.hwp unless hw_profile
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
        self.instances << instance
      end
    end
  end

  def set_new_state
    self.state ||= STATE_NEW
  end

  def state_transition_from_pending(instance)
    if instances.all? {|i| i.state == Instance::STATE_RUNNING}
      self.state = STATE_RUNNING
    elsif partial_launch and instances.all? {|i| i.failed?}
      self.state = STATE_FAILED
    elsif partial_launch and instances.all? {|i| i.failed_or_running?}
      self.state = STATE_INCOMPLETE
    elsif !partial_launch and Instance::FAILED_STATES.include?(instance.state)
      # TODO: now this is done in instance's after_update callback - as part
      # of instance save transaction - this might be done on background by
      # using delayed_job
      deployment_rollback
    end
  end

  def state_transition_from_running(instance)
    if instance.state != STATE_RUNNING
      if instances.all? {|i| i.state == Instance::STATE_STOPPED}
        self.state = STATE_STOPPED
      else
        self.state = STATE_INCOMPLETE
      end
    end
  end

  def state_transition_from_incomplete(instance)
    if instances.all? {|i| i.state == Instance::STATE_RUNNING}
      self.state = STATE_RUNNING
    elsif instances.all? {|i| i.state == Instance::STATE_STOPPED}
      self.state = STATE_STOPPED
    end
  end

  def state_transition_from_shutting_down(instance)
    if instance.state == Instance::STATE_STOPPED and instances.all? {|i| i.inactive?}
      self.state = STATE_STOPPED
    end
  end

  def state_transition_from_rollback_in_progress(instance)
    # TODO: distinguish if an instance was created on provider side
    # or error occurred on create_instance request - in such case
    # the instance has not to be rollbacked
    if Instance::ACTIVE_FAILED_STATES.include?(instance.state)
      # if this instance stop failed, whole deployment rollback failed
      self.state = STATE_ROLLBACK_FAILED
      cleanup_failed_launch
    elsif instance.state == Instance::STATE_RUNNING
      deployment_rollback
    elsif instances.all? {|i| i.finished?}
      # some other instances might be failed (because their
      # launch failed), but it shouldn't be a problem if all
      # running instances stopped correctly
      self.state = STATE_ROLLBACK_COMPLETE
    end
  end

  def deployment_rollback
    unless self.state == STATE_ROLLBACK_IN_PROGRESS
      self.state = STATE_ROLLBACK_IN_PROGRESS
      save!
    end

    if instances.all? {|i| i.inactive? or i.state == Instance::STATE_NEW}
      self.state = STATE_ROLLBACK_COMPLETE
      save!
      return
    end

    delay.send_rollback_requests
  end

  def send_rollback_requests
    error_occured = false
    instances.running.each do |instance|
      error_occured = true unless instance.stop_with_event(nil)
    end
    if error_occured
      cleanup_failed_launch
      self.state = STATE_ROLLBACK_FAILED
      save!
    end
  end

  def log_state_change
    if state_changed?
      self.events << Event.create(
        :source => self,
        :event_time => DateTime.now,
        :status_code => self.state,
        :summary => _("State changed to %s") % self.state
      )
    end
  end

  def handle_completed_rollback
    if self.state_changed? and self.state == STATE_ROLLBACK_COMPLETE
      begin
        if self.events.where(
            :status_code => 'deployment_launch_match').count > 9
          raise "There was too many launch retries, aborting"
        end
        launch!(self.owner)
      rescue
        self.events << Event.create(
          :source => self,
          :event_time => DateTime.now,
          :status_code => 'deployment_launch_failed',
          :summary => _("Failed to launch deployment"),
          :description => $!.message
        )
        update_attribute(:state, STATE_FAILED)
        cleanup_failed_launch
        log_backtrace($!)
      end
    end
  end

  def cleanup_failed_launch
    instances.in_new_state.each do |instance|
      instance.update_attribute(:state, Instance::STATE_CREATE_FAILED)
    end
  end

  include CostEngine::Mixins::Deployment
end
