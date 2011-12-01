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
# Schema version: 20110207110131
#
# Table name: permissions
#
#  id                     :integer         not null, primary key
#  role_id                :integer         not null
#  user_id                :integer         not null
#  permission_object_id   :integer
#  permission_object_type :string(255)
#  lock_version           :integer         default(0)
#  created_at             :datetime
#  updated_at             :datetime
#

class Permission < ActiveRecord::Base
  belongs_to :role
  belongs_to :user

  validates_presence_of :role_id

  validates_presence_of :user_id
  validates_uniqueness_of :user_id, :scope => [:permission_object_id,
                                               :permission_object_type,
                                               :role_id]

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
  belongs_to :base_permission_object, :class_name => "BasePermissionObject",
                                      :foreign_key => "permission_object_id"

end
