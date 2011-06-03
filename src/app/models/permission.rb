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

#
# Copyright (C) 2009 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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
  belongs_to :provider,               :class_name => "Provider",
                                      :foreign_key => "permission_object_id"
  belongs_to :provider_account,          :class_name => "ProviderAccount",
                                      :foreign_key => "permission_object_id"
  belongs_to :template,               :class_name => "Template",
                                      :foreign_key => "permission_object_id"
  belongs_to :assembly,               :class_name => "Assembly",
                                      :foreign_key => "permission_object_id"
  belongs_to :legacy_deployable,             :class_name => "LegacyDeployable",
                                      :foreign_key => "permission_object_id"
  belongs_to :base_permission_object, :class_name => "BasePermissionObject",
                                      :foreign_key => "permission_object_id"

end
