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

class AddDeployableRoles < ActiveRecord::Migration
  VIEW = "view"
  USE  = "use"
  MOD  = "modify"
  CRE  = "create"
  VPRM = "view_perms"
  GPRM = "set_perms"
  NEW_ROLES = {
   Deployable =>
     {"Deployable User"          => [false, {Deployable     => [VIEW,USE]},
                                     "CatalogEntry User"],
      "Deployable Owner"         => [true,  {Deployable     => [VIEW,USE,MOD,VPRM,GPRM]},
                                    "CatalogEntry Owner"]},
   BasePermissionObject =>
     {"Deployable Administrator" => [false, {Deployable => [VIEW,USE,MOD,CRE,VPRM,GPRM]},
                                     "CatalogEntry Administrator"],
      "Deployable Global User"   => [false, {Deployable=> [VIEW,USE]},
                                     "CatalogEntry Global User"],
      "Administrator"          => [false, {Provider     => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           HardwareProfile => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           Realm        => [     USE,MOD,CRE,VPRM,GPRM],
                                           User         => [VIEW,    MOD,CRE],
                                           Pool         => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           Instance     => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Deployment   => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Quota        => [VIEW,    MOD],
                                           PoolFamily   => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           Catalog      => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Deployable => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           BasePermissionObject => [ MOD,    VPRM,GPRM]}]}}
  def self.up
    unless Role.all.size == 0
      Role.transaction do
        NEW_ROLES.each do |role_scope, scoped_hash|
          scoped_hash.each do |role_name, role_def|
            role = Role.find_or_initialize_by_name(role_def[2] ? role_def[2] : role_name)
            role.update_attributes({:name => role_name, :scope => role_scope.name,
                                     :assign_to_owner => role_def[0]})
            role.privileges = {}
            role.save!
            role_def[1].each do |priv_type, priv_actions|
              priv_actions.each do |action|
                Privilege.create!(:role => role, :target_type => priv_type.name,
                                  :action => action)
              end
            end
          end
        end

        MetadataObject.remove("self_service_default_catalog_entry_obj")
        MetadataObject.remove("self_service_default_catalog_entry_role")
        MetadataObject.set("self_service_default_deployable_obj",
                           BasePermissionObject.general_permission_scope)
        MetadataObject.set("self_service_default_deployable_role",
                           Role.find_by_name("Deployable Global User"))
        MetadataObject.set("self_service_perms_list",
                           "[self_service_default_pool,self_service_default_role], [self_service_default_deployable_obj,self_service_default_deployable_role], [self_service_default_pool_global_user_obj,self_service_default_pool_global_user_role], [self_service_default_catalog_global_user_obj,self_service_default_catalog_global_user_role],[self_service_default_hwp_global_user_obj,self_service_default_hwp_global_user_role] ")

      end
    end
  end

  def self.down
  end
end
