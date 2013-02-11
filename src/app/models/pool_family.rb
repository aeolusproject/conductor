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

  before_destroy :check_name!
  before_destroy :check_pools!
  before_destroy :check_images!
  before_destroy :remove_provider_account_assoc

  has_many :pools,  :dependent => :destroy
  belongs_to :quota, :autosave => true, :dependent => :destroy
  has_and_belongs_to_many :provider_accounts, :uniq => true, :order => "provider_accounts.priority asc"
  has_many :permissions, :as => :permission_object, :dependent => :destroy
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"
             has_many :catalogs
  has_many :deployables
  has_many :instances
  has_many :deployments
  has_many :base_images, :class_name => "Tim::BaseImage"
  has_many :templates, :class_name => "Tim::Template"

  accepts_nested_attributes_for :quota

  validates :name, :presence => true,
                   :uniqueness => true,
                   :length => { :within => 1..100 },
                   :format => { :with => /^[\w -]*$/n }
  validates :quota, :presence => true

  def self.default
    MetadataObject.lookup(DEFAULT_POOL_FAMILY_KEY)
  end

  def set_as_default
    MetadataObject.set(DEFAULT_POOL_FAMILY_KEY, self)
  end

  def self.additional_privilege_target_types
    [Pool, Quota, Tim::BaseImage, Tim::Template]
  end

  def derived_subtree(role = nil)
    subtree = super(role)
    subtree += pools if (role.nil? or role.privilege_target_match(Pool))
    subtree += deployments if (role.nil? or role.privilege_target_match(Deployment))
    subtree += instances if (role.nil? or role.privilege_target_match(Instance))
    subtree += catalogs if (role.nil? or role.privilege_target_match(Deployable))
    subtree += deployables if (role.nil? or role.privilege_target_match(Deployable))
    subtree += base_images if (role.nil? or role.privilege_target_match(Tim::BaseImage))
    subtree += templates if (role.nil? or role.privilege_target_match(Tim::Template))
    subtree
  end

  def check_pools!
    cant_destroy = pools.find_all {|p| !p.destroyable?}
    if cant_destroy.empty?
      true
    else
      raise Aeolus::Conductor::Base::NotDestroyable,
        _('Can not destroy following pools: %s.') % cant_destroy.map{|p| p.name}.join(', ')
    end
  end

  def check_name!
    if self == PoolFamily.default
      raise Aeolus::Conductor::Base::NotDestroyable,
        _('The default Environment cannot be deleted.')
    else
      true
    end
  end

  def check_images!
    if base_images.empty?
      true
    else
      raise Aeolus::Conductor::Base::NotDestroyable,
        _('There are following associated images: %s. Delete them first.') % base_images.map{|i| i.name}.join(', ')
    end
  end

  def remove_provider_account_assoc
    provider_accounts.clear
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
    statistics = {
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
end
