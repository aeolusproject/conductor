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

class DeploymentRoles < ActiveRecord::Migration
  VIEW = "view"
  USE  = "use"
  MOD  = "modify"
  CRE  = "create"
  VPRM = "view_perms"
  GPRM = "set_perms"
  NEW_ROLES = {
    Deployment =>
     {"Deployment Controller"  => [false, {Deployment => [VIEW,USE],
                                           Instance   => [VIEW]}],
      "Deployment Owner"       => [true,  {Deployment => [VIEW,USE,MOD,    VPRM,GPRM],
                                           Instance   => [VIEW,USE,MOD]}]},
    Pool =>
     {"Pool User"              => [false, {Pool         => [VIEW],
                                           Instance     => [             CRE],
                                           Deployment   => [             CRE],
                                           Quota        => [VIEW]}],
      "Pool Owner"             => [true,  {Pool         => [VIEW,    MOD,    VPRM,GPRM],
                                           Instance     => [VIEW,USE,MOD,CRE],
                                           Deployment   => [VIEW,USE,MOD,CRE],
                                           Quota        => [VIEW]}]},
   BasePermissionObject =>
    {"Pool Administrator"     => [false, {Pool         => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           Instance     => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Deployment   => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Quota        => [VIEW,    MOD],
                                           PoolFamily   => [VIEW,    MOD,CRE,VPRM,GPRM]}],
      "Administrator"          => [false, {Provider     => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           ProviderAccount => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           HardwareProfile => [      MOD,CRE,VPRM,GPRM],
                                           Realm        => [     USE,MOD,CRE,VPRM,GPRM],
                                           User         => [VIEW,    MOD,CRE],
                                           Pool         => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           Instance     => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Deployment   => [VIEW,USE,MOD,CRE,VPRM,GPRM],
                                           Quota        => [VIEW,    MOD],
                                           PoolFamily   => [VIEW,    MOD,CRE,VPRM,GPRM],
                                           BasePermissionObject => [ MOD,    VPRM,GPRM]}]}}
  def self.up
    unless Role.all.size == 0
      Role.transaction do
        NEW_ROLES.each do |role_scope, scoped_hash|
          scoped_hash.each do |role_name, role_def|
            role = Role.find_or_initialize_by_name(role_name)
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
      end
    end
  end

  def self.down
  end
end
