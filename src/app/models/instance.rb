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
# Table name: instances
#
#  id                      :integer         not null, primary key
#  external_key            :string(255)
#  name                    :string(1024)    not null
#  hardware_profile_id     :integer         not null
#  frontend_realm_id       :integer
#  owner_id                :integer
#  pool_id                 :integer         not null
#  provider_account_id     :integer
#  instance_hwp_id         :integer
#  public_addresses        :string(255)
#  private_addresses       :string(255)
#  state                   :string(255)
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
#  deployment_id           :integer
#  assembly_xml            :text
#  instance_config_xml     :text
#  image_uuid              :string(255)
#  image_build_uuid        :string(255)
#  provider_image_uuid     :string(255)
#  provider_instance_id    :string(255)
#  user_data               :string(255)
#  uuid                    :string(255)
#  secret                  :string(255)
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'util/deployable_xml'
require 'util/instance_config_xml'

class Instance < ActiveRecord::Base
  acts_as_paranoid

  class << self
    include CommonFilterMethods
  end
  include PermissionedObject

  before_destroy :destroyable?

  belongs_to :pool
  belongs_to :pool_family
  belongs_to :provider_account
  belongs_to :deployment

  belongs_to :hardware_profile
  belongs_to :frontend_realm
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  belongs_to :instance_hwp

  has_one :instance_key, :dependent => :destroy
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"

  has_many :events, :as => :source, :dependent => :destroy,
           :order => 'events.id ASC'
  has_many :instance_parameters, :dependent => :destroy
  has_many :instance_matches, :dependent => :destroy
  has_many :tasks, :as =>:task_target, :dependent => :destroy
  after_create "assign_owner_roles(owner)"

  validates_presence_of :pool_id
  validates_presence_of :hardware_profile_id

  #validates_presence_of :external_key
  # TODO: can we do uniqueness validation on indirect association
  # -- pool.account.provider
  #validates_uniqueness_of :external_key, :scope => :provider_id

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:pool_id, :deleted_at]
  validates_length_of :name, :maximum => 1024

  before_create :generate_uuid
  before_create :set_pool_family

  STATE_NEW            = "new"
  STATE_PENDING        = "pending"
  STATE_RUNNING        = "running"
  STATE_SHUTTING_DOWN  = "shutting_down"
  STATE_STOPPED        = "stopped"
  STATE_STOPPING       = "stopping"
  STATE_CREATE_FAILED  = "create_failed"
  STATE_ERROR          = "error"
  STATE_VANISHED       = "vanished"

  STATES = [STATE_NEW, STATE_PENDING, STATE_RUNNING,
             STATE_SHUTTING_DOWN, STATE_STOPPED, STATE_CREATE_FAILED,
             STATE_ERROR, STATE_VANISHED]

  STOPPABLE_INACCESSIBLE_STATES = [STATE_NEW, STATE_PENDING, STATE_RUNNING, STATE_SHUTTING_DOWN]
  # States that indicate some sort of failure/problem with an instance:
  FAILED_STATES = [STATE_CREATE_FAILED, STATE_ERROR, STATE_VANISHED]
  ACTIVE_FAILED_STATES = [STATE_ERROR, STATE_VANISHED]

  scope :deployed,  :conditions => { :state => [STATE_RUNNING, STATE_SHUTTING_DOWN] }
  # FIXME: "pending" is misleading as it doesn't just cover STATE_PENDING
  scope :pending,   :conditions => { :state => [STATE_NEW, STATE_PENDING] }
  scope :running,   :conditions => { :state => [STATE_RUNNING] }
  scope :in_new_state, :conditions => { :state => [STATE_NEW] }
  scope :pending_or_deployed,   :conditions => { :state => [STATE_NEW, STATE_PENDING, STATE_RUNNING, STATE_SHUTTING_DOWN] }
  # FIXME: "failed" is misleading too...
  scope :failed,    :conditions => { :state => FAILED_STATES }
  scope :stopped,   :conditions => {:state => STATE_STOPPED}
  scope :not_stopped, :conditions => "state <> 'stopped'"
  scope :stoppable,    :conditions => { :state => [STATE_PENDING, STATE_RUNNING] }
  scope :stoppable_inaccessible,    :conditions => { :state => STOPPABLE_INACCESSIBLE_STATES }

  SEARCHABLE_COLUMNS = %w(name state)

  validates_inclusion_of :state,
     :in => STATES

  validate :pool_and_account_enabled_validation, :on => :create

  before_destroy :destroy_on_provider
  # A user should only be able to update certain attributes, but the API may permit other attributes to be
  # changed if called from another Aeolus component, so attr_protected isn't quite what we want:
  USER_MUTABLE_ATTRS = ['name']

  def perm_ancestors
    ancestors = super
    ancestors << deployment unless deployment.nil?
    ancestors += [pool, pool_family]
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

  def pool_and_account_enabled_validation
    errors.add(:pool, _('must be enabled')) unless pool and pool.enabled?
    errors.add(:pool, _('has all associated Providers disabled')) if pool and pool.pool_family.all_providers_disabled?
  end


  def image
    @image ||= Tim::BaseImage.find_by_uuid(image_uuid) if image_uuid
  end

  def image_build
    @image_build ||= Tim::ImageVersion.find_by_uuid(image_build_uuid) if image_build_uuid
  end

  def provider_image_for_account(provider_account)
    if image_build
      Tim::ProviderImage.find_by_provider_account_and_image_version(
        provider_account, image_build).complete.first
    elsif image
      Tim::ProviderImage.find_by_provider_account_and_image(
        provider_account, image).complete.order('created_at DESC').first
    else
      nil
    end
  end

  def assembly_xml
    @assembly_xml ||= AssemblyXML.new(self[:assembly_xml].to_s)
  end

  def instance_config_xml
    if not self[:instance_config_xml].nil?
      @instance_config_xml ||= InstanceConfigXML.new(self[:instance_config_xml].to_s)
    end
  end

  # Provide method to check if requested action exists, so caller can decide
  # if they want to throw an error of some sort before continuing
  # (ie in service api)
  def valid_action?(action)
    return get_action_list.include?(action) ? true : false
  end

  def queue_action(user, action, data = nil)
    return false unless get_action_list.include?(action)
    task = InstanceTask.create!({ :user        => user,
                                  :task_target => self,
                                  :action      => action,
                                  :args        => data})

    event = Event.create!(:source => self, :event_time => Time.now,
                          :summary => "#{action} action queued",
                          :status_code => "#{action}_queued")

    return task
  end

  # Returns the total time that this instance has been in the state
  def total_state_time(state)

    if !STATES.include?(state)
      return _('Error, could not calculate state time: invalid state')
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
        return _('Error, could not calculate state time: state is not monitored')
    end
  end

  def create_auth_key
    raise "instance provider_account is not set" unless self.provider_account
    client = self.provider_account.connect
    return nil unless client && client.feature?(:instances, :authentication_key)
    if key = client.create_key(:name => key_name)
      self.instance_key = InstanceKey.create!(:pem => key.pem, :name => key.id, :instance => self)
      self.save!
    end
  end

  def self.get_user_instances_stats(session, user)
    stats = {
      :running_instances => 0,
      :stopped_instances => 0,
    }

    instances = []
    pools = Pool.list_for_user(session, user, Privilege::VIEW, Instance)
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

  USER_DATA_VERSION = "1"
  OAUTH_SECRET_SEED = [('a'..'z'),('A'..'Z'),(0..9)].map{|i| i.to_a}.flatten
  def self.generate_oauth_secret
    # generates a string of between 40 and 50 characters consisting of a
    # random selection of alphanumeric (upper and lower case) characters
    (0..(rand(10) + 40)).map { OAUTH_SECRET_SEED[rand(OAUTH_SECRET_SEED.length)] }.join
  end

  def generate_user_data(config_server)
    ["#{USER_DATA_VERSION}|#{config_server.endpoint}|#{uuid}|#{secret}"].pack("m0").delete("\n")
  end

  def add_instance_config!(config_server, config)
    self.user_data = generate_user_data(config_server)
    self.instance_config_xml = config.to_s
    save!
    begin
      config_server.send_config(config)
    rescue Errno::ECONNREFUSED
      raise _('Cannot connect to the Config Server')
    end
  end

  def restartable?
    # TODO: we don't support stateful instances yet, so it's `false` for the time being.
    # In the meantime, we can use this method to write validation code for cases
    # where does matter whether an instance is stateful or stateless.
    false
  end

  def destroyable?
    (state == STATE_CREATE_FAILED) || (state == STATE_STOPPED && ! restartable?) || (state == STATE_VANISHED)
  end

  def failed?
    FAILED_STATES.include?(state)
  end

  def inactive?
    (FAILED_STATES + [STATE_STOPPED]).include?(state)
  end

  def failed_or_running?
    (FAILED_STATES + [STATE_RUNNING]).include?(state)
  end

  def requires_config_server?
    ! instance_config_xml.nil? || assembly_xml.requires_config_server?
  end

  # represents states from which instance doesn't automatically transits
  # into any other state, also checks that there is no queued 'start' action
  # for stopped instance (rhevm, vpshere)
  def finished?
    return false if state == Instance::STATE_STOPPED && pending_or_successful_start?
    inactive? || state == Instance::STATE_NEW
  end

  def self.list(order_field, order_dir)
    #Instance.all(:include => [ :owner ],
    #             :order => (order_field || 'name') +' '+ (order_dir || 'asc'))
    includes(:owner).order((order_field || 'name') +' '+ (order_dir || 'asc'))
  end

  def image_arch
    # try to get architecture of the image associated with this instance
    # for imported images template is empty -> architecture is not set,
    # in this case we omit this check
    return image.template.os.arch
  rescue => e
    logger.warn "failed to get image architecture for instance '#{name}', skipping architecture check: #{e}"
    nil
  end

  def matches
    errors = []
    if pool.pool_family.provider_accounts.empty?
      errors << _('There are no Provider Accounts associated with the selected Pool\'s Environment.')
    end
    errors << _('Pool quota reached') if pool.quota.reached?
    errors << _('Environment quota reached') if pool.pool_family.quota.reached?
    errors << _('User quota reached') if owner.quota.reached?
    errors << _('No image build was found with uuid %s and no image was found with uuid %s') % [image_build_uuid, image_uuid] if image_build.nil? and image.nil?
    arch = image_arch
    if arch.present? and hardware_profile.architecture and hardware_profile.architecture.value != arch
      errors << _('Assembly hardware profile architecture (\'%s\') doesn\'t match image hardware profile architecture (\'%s\').') % [hardware_profile.architecture.value, arch]
    end
    return [[], errors] unless errors.empty?

    matched = []
    pool.pool_family.provider_accounts_by_priority.each do |account|
      account.instance_matches(self, matched, errors)
    end

    [matched, errors]
  end

  def includes_instance_match?(match)
    instance_matches.any?{|m| m.equals?(match)}
  end

  def launch!(match, user, config_server, config)
    # create a taskomatic task
    task = InstanceTask.create!({:user        => user,
                                 :task_target => self,
                                 :action      => InstanceTask::ACTION_CREATE})
    Taskomatic.create_instance!(task, match, config_server, config)
  end


  def self.csv_export(instances)
    csvm = get_csv_class
    csv_string = csvm.generate(:col_sep => ";", :row_sep => "\r\n") do |csv|
      event_attributes = Event.new.attributes.keys.reject {|key| key if key == "created_at" || key == "updated_at"}

      csv << event_attributes.map {|event| event.capitalize }

      events = instances.map{|i| i.events}.flatten!
      unless events.nil?
        events.each do |event|
          csv << event_attributes.map {|event_attribute| event[event_attribute] }
        end
      end
    end
    csv_string
  end

  scope :with_hardware_profile, lambda {
      {:include => :hardware_profile}
  }

  def as_json(options={})
    available_actions = get_action_list
    json = super(options).merge({
      :provider => provider_account ? provider_account.provider.name : '',
      :has_key => !(instance_key.nil?),
      :uptime => ApplicationHelper.count_uptime(uptime),
      :stop_enabled => available_actions.include?(InstanceTask::ACTION_STOP),
      :reboot_enabled => available_actions.include?(InstanceTask::ACTION_REBOOT),
      :translated_state => I18n.t("instances.states.#{state}"),
      :is_failed => failed?
    })

    json[:owner] = owner.name if owner.present?

    json
  end

  def first_running?
    not deployment.instances.deployed.any? {|i| i != self}
  end

  def stop(user)
    do_operation(user, 'stop')
  end


  def start(user)
    do_operation(user, 'start')
  end

  def stop_with_event(user)
    stop(user)
    true
  rescue
    self.events << Event.create(
      :source => self,
      :event_time => DateTime.now,
      :status_code => 'instance_stop_failed',
      :summary => "Failed to stop instance #{self.name}",
      :description => $!.message
    )
    log_backtrace($!)
    false
  end

  def reboot(user)
    if tasks.where("action = :action AND time_submitted > :time_ago",
       {:action => "reboot", :time_ago => 2.minutes.ago}).present?
      raise _('reboot is already scheduled.')
    else
      do_operation(user, 'reboot')
    end
  end

  def forced_stop(user)
    self.state = STATE_STOPPED
    save!
    event = Event.create!(:source => self, :event_time => Time.now,
                          :summary => "Instance is not accessible, state changed to stopped",
                          :status_code => "forced_stop")
  end

  def deployed?
    [STATE_RUNNING, STATE_SHUTTING_DOWN].include?(state)
  end

  def stopped?
    [STATE_STOPPED].include?(state)
  end

  def pending?
    [STATE_NEW, STATE_PENDING].include?(state)
  end

  def uptime
    deployed? ? (Time.now - time_last_running) : 0
  end

  def stopped_after_creation?
    last_task = tasks.last
    state == Instance::STATE_STOPPED &&
      # TODO: to keep backward compatibility with dc-core 0.5
      # time_last_pending can't be used, because pending
      # state was used instead of shutting_down in older dc-api version.
      # https://bugzilla.redhat.com/show_bug.cgi?id=857542
      #time_last_pending.to_i > time_last_running.to_i &&
      last_task &&
      [InstanceTask::ACTION_CREATE, InstanceTask::ACTION_START].include?(last_task.action) &&
      last_task.created_at.to_i > time_last_running.to_i &&
      # also make sure that the 'create' task was created after
      # last deployment launch request - instance can be stopped
      # since previous rollback+retry request
      last_task.created_at.to_f > last_launch_time.to_f &&
      provider_account &&
      provider_account.provider.provider_type.goes_to_stop_after_creation?
  end

  def in_startable_state?
    # returns true if this instance is part of a deployment and this deployment
    # is in any of rollback modes
    return true if deployment.nil?
    Deployment::INSTANCE_STARTABLE_STATES.include?(deployment.state)
  end

  def requires_explicit_start?
    # this is for RHEVM/VSPHERE instances where instance goes to 'stopped' state
    # after creation - we check if it wasn't running before this stopped state
    # and if we already did send start request to it
    in_startable_state? && stopped_after_creation? &&
      !pending_or_successful_start?
  end

  def stuck_in_stopping?
    state == Instance::STATE_SHUTTING_DOWN &&
      Time.now - time_last_shutting_down > 120 &&
      provider_account &&
      provider_account.provider.provider_type.goes_to_stop_after_creation?
  end

  PRESET_FILTERS_OPTIONS = [
    {:title => "instances.preset_filters.other_than_stopped", :id => "other_than_stopped", :query => where("instances.state != ?", "stopped")},
    {:title => "instances.preset_filters.new", :id => "new", :query => where("instances.state" => "new")},
    {:title => "instances.preset_filters.pending", :id => "pending", :query => where("instances.state" => "pending")},
    {:title => "instances.preset_filters.running", :id => "running", :query => where("instances.state" => "running")},
    {:title => "instances.preset_filters.shutting_down", :id => "shutting_down", :query => where("instances.state" => "shutting_down")},
    {:title => "instances.preset_filters.stopped", :id => "stopped", :query => where("instances.state" => "stopped")},
    {:title => "instances.preset_filters.create_failed", :id => "create_failed", :query => where("instances.state" => "create_failed")},
    {:title => "instances.preset_filters.error", :id => "error", :query => where("instances.state" => "error")},
    {:title => "instances.preset_filters.vanished", :id => "vanished", :query => where("instances.state" => "vanished")}
  ]

  def destroy_on_provider
    if provider_account and provider_account.provider.provider_type.destroy_supported? and ![STATE_CREATE_FAILED, STATE_VANISHED].include?(state)
      task = self.queue_action(self.owner, 'destroy')
      raise _('Destroy cannot be performed on this instance.') unless task
      Taskomatic.destroy_instance(task)
    end
  end

  def self.stoppable_inaccessible_instances(instances)
    failed_accounts = {}
    instances.select do |i|
      next unless STOPPABLE_INACCESSIBLE_STATES.include?(i.state)
      next unless i.provider_account
      unless failed_accounts.has_key?(i.provider_account.id)
        failed_accounts[i.provider_account.id] = i.provider_account.connect.nil?
      end
      failed_accounts[i.provider_account.id]
    end
  end

  def reset_attrs
    # TODO: is it OK to upload params to config server multiple times?
    # do we now keep instance config on config server by default?
    update_attributes(:state => Instance::STATE_NEW,
                      :provider_account => nil,
                      :public_addresses => nil,
                      :private_addresses => nil)
    instance_key.destroy if instance_key
  end

  def stop_request_queued?
    task = tasks.last
    task && task.action == InstanceTask::ACTION_STOP &&
      task.state == Task::STATE_FINISHED
  end

  def disappears_after_stop_request?
    provider_account &&
      provider_account.provider.provider_type.stopped_instances_disappear?
  end

  private

  def self.apply_search_filter(search)
    if search
      where("lower(instances.name) LIKE :search OR lower(instances.state) LIKE :search", :search => "%#{search.downcase}%")
    else
      scoped
    end
  end

  def key_name
    "#{self.name}_#{Time.now.to_i}_key_#{self.object_id}".gsub(/[^a-zA-Z0-9\.\-]/, '_')
  end

  def generate_uuid
    self[:uuid] = UUIDTools::UUID.timestamp_create.to_s
  end

  def set_pool_family
    self[:pool_family_id] = pool.pool_family_id
  end

  def do_operation(user, operation)
    task = self.queue_action(user, operation)
    unless task
      raise I18n.t("instances.errors.#{operation}_invalid_action")
    end
    Taskomatic.send("#{operation}_instance", task)
  end

  def pending_or_successful_start?
    task = tasks.last
    return false if task.nil? || task.action != 'start'
    return true if task.state == Task::STATE_FINISHED
    # it's possible that start request takes more than 30 secs on rhevm,
    # but dbomatic kills child process after 30sec by default, so
    # task may stay in 'pending' state. If task is in pending state for
    # more than 2 mins, consider previous start request as failed.
    return true if task.state == Task::STATE_PENDING &&
      Time.now - task.created_at < 120
    false
  end

  def last_launch_time
    return nil if deployment.nil?
    event = deployment.events.find_last_by_status_code(:pending)
    event.nil? ? nil : event.created_at
  end

  include CostEngine::Mixins::Instance
end
