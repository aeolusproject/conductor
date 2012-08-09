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

class DerivedPermission < ActiveRecord::Base
  class << self
    include CommonFilterMethods
  end
  # the source permission for the denormalized object
  belongs_to :permission
  validates_presence_of :permission_id

  # this is the object used for permission checks
  belongs_to :permission_object,      :polymorphic => true
  # type-specific associations
  belongs_to :pool_family,            :class_name => "PoolFamily",
                                      :foreign_key => "permission_object_id"
  belongs_to :pool,                   :class_name => "Pool",
                                      :foreign_key => "permission_object_id"
  belongs_to :instance,               :class_name => "Instance",
                                      :foreign_key => "permission_object_id"
  belongs_to :deployment,             :class_name => "Deployment",
                                      :foreign_key => "permission_object_id"
  belongs_to :deployable,             :class_name => "Deployable",
                                      :foreign_key => "permission_object_id"
  belongs_to :catalog,                :class_name => "Catalog",
                                      :foreign_key => "permission_object_id"
  belongs_to :provider,               :class_name => "Provider",
                                      :foreign_key => "permission_object_id"
  belongs_to :provider_account,          :class_name => "ProviderAccount",
                                      :foreign_key => "permission_object_id"
  belongs_to :hardware_profile,       :class_name => "hardwareProfile",
                                      :foreign_key => "permission_object_id"
  belongs_to :base_permission_object, :class_name => "BasePermissionObject",
                                      :foreign_key => "permission_object_id"

  # role is copied from source permission
  belongs_to :role
  validates_presence_of :role_id

  # entity is copied from source permission
  belongs_to :entity
  validates_presence_of :entity_id

  validates_uniqueness_of :permission_id, :scope => [:permission_object_id,
                                                     :permission_object_type]

  # :query is handled differently for permission
  PRESET_FILTERS_OPTIONS = [
    {:title => "permissions.preset_filters.user_permissions",
     :id => "user_permissions",
     :includes => :entity,
     :where => {"entities.entity_target_type" => "User"}},
    {:title => "permissions.preset_filters.group_permissions",
     :id => "group_permissions",
     :includes => :entity,
     :where => {"entities.entity_target_type" => "UserGroup"}}
  ]

  PROFILE_PRESET_FILTERS_OPTIONS = [
    {:title => "permissions.global",
     :id => "base_permission_object_permissions",
     :includes => [:entity, :base_permission_object],
     :where => {"permission_object_type" => "BasePermissionObject"}},
    {:title => "activerecord.models.provider",
     :id => "provider_permissions",
     :includes => [:entity, :provider],
     :where => {"permission_object_type" => "Provider"},
     :search_fields => ["providers.name"]},
    {:title => "activerecord.models.provider_account",
     :id => "provider_account_permissions",
     :includes => [:entity, {:provider_account => :provider}],
     :where => {"permission_object_type" => "ProviderAccount"},
     :search_fields => ["provider_accounts.label", "providers.name"]},
    {:title => "activerecord.models.pool",
     :id => "pool_permissions",
     :includes => [:entity, :pool],
     :where => {"permission_object_type" => "Pool"},
     :search_fields => ["pools.name"]},
    {:title => "activerecord.models.pool_family",
     :id => "pool_family_permissions",
     :includes => [:entity, :pool_family],
     :where => {"permission_object_type" => "PoolFamily"},
     :search_fields => ["pool_families.name"]},
    {:title => "activerecord.models.catalog",
     :id => "catalog_permissions",
     :includes => [:entity, :catalog],
     :where => {"permission_object_type" => "Catalog"},
     :search_fields => ["catalogs.name"]},
    {:title => "activerecord.models.deployable",
     :id => "deployable_permissions",
     :includes => [:entity, :deployable],
     :where => {"permission_object_type" => "Deployable"},
     :search_fields => ["deployables.name"]},
    {:title => "activerecord.models.deployment",
     :id => "deployment_permissions",
     :includes => [:entity, :deployment],
     :where => {"permission_object_type" => "Deployment"},
     :search_fields => ["deployments.name"]},
    {:title => "activerecord.models.instance",
     :id => "instance_permissions",
     :includes => [:entity, :instance],
     :where => {"permission_object_type" => "Instance"},
     :search_fields => ["instances.name"]}
  ]
  def self.apply_search_filter(search)
    search, preset_filter_id = search
    if search
      if preset_filter_id
        search_fields = PROFILE_PRESET_FILTERS_OPTIONS.select { |item|
          item[:id] == preset_filter_id
        }.first[:search_fields]
        search_fields = [] if search_fields.nil?
      else
        search_fields = []
      end
      where_str = "lower(entities.name) LIKE :search OR lower(roles.name) LIKE :search"
      search_fields.each do |search_field|
        where_str += " OR lower(#{search_field}) LIKE :search"
      end
      includes([:entity, :role]).where(where_str, :search => "%#{search.downcase}%")
    else
      scoped
    end
  end

end
