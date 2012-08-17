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
# Table name: pool_families
#
#  id           :integer         not null, primary key
#  name         :string(255)     not null
#  description  :string(255)
#  lock_version :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#  quota_id     :integer
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class PoolFamily < ActiveRecord::Base
  include PermissionedObject
  include ActionView::Helpers::NumberHelper
  DEFAULT_POOL_FAMILY_KEY = "default_pool_family"

  after_update :fix_iwhd_environment_tags

  has_many :pools,  :dependent => :destroy
  belongs_to :quota, :dependent => :destroy
  accepts_nested_attributes_for :quota
  has_and_belongs_to_many :provider_accounts, :uniq => true, :order => "provider_accounts.priority asc"
  has_many :permissions, :as => :permission_object, :dependent => :destroy
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"

  has_many :catalogs
  has_many :deployables
  has_many :instances
  has_many :deployments

  validates_length_of :name, :maximum => 255
  validates_format_of :name, :with => /^[\w -]*$/n

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :quota

  before_destroy :destroyable?

  def self.default
    MetadataObject.lookup(DEFAULT_POOL_FAMILY_KEY)
  end

  def set_as_default
    MetadataObject.set(DEFAULT_POOL_FAMILY_KEY, self)
  end

  def derived_subtree(role = nil)
    subtree = super(role)
    subtree += pools if (role.nil? or role.privilege_target_match(Pool))
    subtree += deployments if (role.nil? or role.privilege_target_match(Deployment))
    subtree += instances if (role.nil? or role.privilege_target_match(Instance))
    subtree += catalogs if (role.nil? or role.privilege_target_match(Deployable))
    subtree += deployables if (role.nil? or role.privilege_target_match(Deployable))
  end

  def self.additional_privilege_target_types
    [Pool, Quota]
  end

  def destroyable?
    # A PoolFamily is destroyable if its pools are destroyable and it is not  the default PoolFamily
    pools.all? {|p| p.destroyable? } && self != PoolFamily.default
  end

  def all_providers_disabled?
    !provider_accounts.empty? and !provider_accounts.any? {|acc| acc.provider.enabled?}
  end

  def provider_accounts_by_priority
    provider_accounts.sort {|a,b|
      if a.priority.nil? and b.priority.nil?
        0
      elsif a.priority.nil?
        1
      elsif b.priority.nil?
        -1
      else
        a.priority <=> b.priority
      end
    }
  end

  def statistics
    max = quota.maximum_running_instances
    total = quota.running_instances
    avail = max - total unless max.nil?
    # Don't make repeat calls to the pools association
    cached_pools = pools
    {
      :deployments => cached_pools.collect{|p| p.deployments.count}.sum,
      :total_instances => cached_pools.collect{|p| p.instances.not_stopped.count}.sum,
      :instances_pending => cached_pools.collect{|p| p.instances.pending.count}.sum,
      :instances_failed => cached_pools.collect{|p| p.instances.failed.count}.sum,
      :used_quota => total,
      :quota_percent => number_to_percentage(quota.percentage_used,
                                             :precision => 0),
      :available_quota => avail,
    }
  end

  def build_targets
    targets = []
    ProviderAccount.enabled.group_by_type(self).each do |driver, group|
      targets << driver if group[:included]
    end
    targets
  end

  def fix_iwhd_environment_tags
    if name_changed?
      Aeolus::Image::Warehouse::Image.by_environment(name_was).each do |image|
        image.set_attr("environment", name)
      end
    end
  end
end
