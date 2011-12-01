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

class AddHwpGlobalUserRole < ActiveRecord::Migration
  ROLE_NAME = "HWP Global User"
  VIEW = "view"
  USE = "use"
  META_OBJ = "self_service_default_hwp_global_user_obj"
  META_ROLE = "self_service_default_hwp_global_user_role"
  META_PERMS = "self_service_perms_list"
  AGGREGATE_PERMS = "[self_service_default_pool,self_service_default_role], [self_service_default_catalog_entry_obj,self_service_default_catalog_entry_role], [self_service_default_pool_global_user_obj,self_service_default_pool_global_user_role], [self_service_default_hwp_global_user_obj,self_service_default_hwp_global_user_role]"
  ROLE_DEF = [false, {HardwareProfile => [VIEW, USE]}]

  def self.up
    return if Role.all.empty?
    Role.transaction do
      role = Role.find_or_initialize_by_name(ROLE_NAME)
      role.update_attributes({:name => ROLE_NAME, :scope => BasePermissionObject.name, :assign_to_owner => ROLE_DEF[0]})
      role.save!
      ROLE_DEF[1].each do |priv_type, priv_actions|
        priv_actions.each do |action|
          Privilege.create!(:role => role, :target_type => priv_type.name,
                            :action => action)
        end
      end

      MetadataObject.transaction do
        settings = {
          META_OBJ => BasePermissionObject.general_permission_scope,
          META_ROLE => Role.find_by_name(ROLE_NAME),
          META_PERMS => AGGREGATE_PERMS }
        settings.each_pair { |key, value| MetadataObject.set(key, value) }
      end

      Permission.transaction do
        User.all.each do |user|
          default_obj = MetadataObject.lookup(META_OBJ)
          default_role = MetadataObject.lookup(META_ROLE)
          unless Permission.first(:conditions => {:user_id => user.id,
                                                  :role_id => default_role.id,
                                                  :permission_object_id => default_obj.id})
            Permission.create!(:user => user,
                              :role => default_role,
                              :permission_object => default_obj)
          end
        end
      end
    end
  end

  def self.down
  end
end
