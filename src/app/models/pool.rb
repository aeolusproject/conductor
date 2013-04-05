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
# Schema version: 20110603204130
#
# Table name: pools
#
#  id             :integer         not null, primary key
#  name           :string(255)     not null
#  exported_as    :string(255)
#  quota_id       :integer
#  pool_family_id :integer         not null
#  lock_version   :integer         default(0)
#  created_at     :datetime
#  updated_at     :datetime
#  enabled        :boolean
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Pool < ActiveRecord::Base

  include Alberich::PermissionedObject
  include ActionView::Helpers::NumberHelper
  class << self
    include CommonFilterMethods
  end

  before_destroy :destroyable?

  has_many :instances,  :dependent => :destroy
  belongs_to :quota, :autosave => true, :dependent => :destroy
  belongs_to :pool_family
  has_many :deployments, :dependent => :destroy
  has_many :catalogs, :dependent => :destroy
  has_many :provider_selection_strategies, :dependent => :destroy
  has_many :provider_priority_groups, :dependent => :destroy
  has_many :pool_provider_account_options, :dependent => :destroy

  accepts_nested_attributes_for :quota

  validates :name, :presence => true,
                   :uniqueness => { :scope => :pool_family_id },
                   :length => { :within => 1..100 },
                   :format => { :with => /^[\w -]*$/n }
  validates :quota, :presence => true
  validates :pool_family_id, :presence => true
  validates :enabled, :inclusion => [true, false]
  validates :exported_as, :uniqueness => true, :allow_blank => true

  PRESET_FILTERS_OPTIONS = [
      {:title => "pools.preset_filters.enabled_pools", :id => "enabled_pools", :query => where("pools.enabled" => true)},
      {:title => "pools.preset_filters.with_pending_instances", :id => "with_pending_instances", :query => includes(:deployments => :instances).where("instances.state" => "pending")},
      {:title => "pools.preset_filters.with_running_instances", :id => "with_running_instances", :query => includes(:deployments => :instances).where("instances.state" => "running")},
      {:title => "pools.preset_filters.with_create_failed_instances", :id => "with_create_failed_instances", :query => includes(:deployments => :instances).where("instances.state" => "create_failed")},
      {:title => "pools.preset_filters.with_stopped_instances", :id => "with_stopped_instances", :query => includes(:deployments => :instances).where("instances.state" => "stopped")}
  ]

  def self.additional_privilege_target_types
    [Deployment, Instance, Catalog, Quota]
  end

  def self.list(order_field, order_dir)
    Pool.all(:include => [ :quota, :pool_family ],
             :order => (order_field || 'name') +' '+ (order_dir || 'asc'))
  end

  def cloud_accounts
    accounts = []
    instances.each do |instance|
      if instance.provider_account and !accounts.include?(instance.provider_account)
        accounts << instance.provider_account
      end
    end
  end

  def destroyable?
    instances.all? {|i| i.destroyable? }
  end

  def failed_instances
    instances.select {|instance| instance.failed?}
  end

  def not_stopped_instances
    instances.select {|instance| !instance.stopped?}
  end

  def deployed_instances
    instances.select {|instance| instance.deployed?}
  end

  def pending_instances
    instances.select {|instance| instance.pending?}
  end

  # TODO: Implement Alerts and Updates
  def statistics(permission_session=nil, user = nil)
    # TODO - Need to set up cache invalidation before this is safe
    #Rails.cache.fetch("pool-#{id}-statistics") do
    max = quota.maximum_running_instances
    total = quota.running_instances
    avail = max - total unless max.nil?
    all_failed = instances.failed
    failed = (user.nil? || all_failed.empty? ? all_failed :
              all_failed.list_for_user(permission_session, user, Alberich::Privilege::VIEW))
    pool_family_quota_percent = pool_family.quota.percentage_used quota.running_instances
    {
      :cloud_providers => instances.includes(:provider_account).collect{|i| i.provider_account}.uniq.count,
      :deployments => deployments.size,
      :total_instances => not_stopped_instances.count,
      :instances_deployed => deployed_instances.count,
      :instances_pending => pending_instances.count,
      :instances_failed => failed,
      :instances_failed_visible_count => failed.count,
      :instances_failed_count => all_failed.count,
      :used_quota => quota.running_instances,
      :quota_percent => number_to_percentage(quota.percentage_used,
                                             :precision => 0),
      :pool_family_quota_percent => number_to_percentage(pool_family_quota_percent, :precision => 0),
      :available_quota => avail
    }
  end

  def perm_ancestors
    super + [pool_family]
  end

  def derived_subtree(role = nil)
    subtree = super(role)
    subtree += deployments if (role.nil? or role.privilege_target_match(Deployment))
    subtree += instances if (role.nil? or role.privilege_target_match(Instance))
    subtree += catalogs if (role.nil? or role.privilege_target_match(Deployable))
    subtree += catalogs.collect {|c| c.deployables}.flatten.uniq if (role.nil? or role.privilege_target_match(Deployable))
    subtree
  end

  private

  def self.apply_search_filter(search)
    return scoped unless search
    includes(:pool_family).where("lower(pools.name) LIKE :search OR lower(pool_families.name) LIKE :search", :search => "%#{search.downcase}%")
  end

end
