#
#   Copyright 2012 Red Hat, Inc.
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

class AddImageAdministratorRole < ActiveRecord::Migration
  VIEW = "view"
  USE  = "use"
  MOD  = "modify"
  CRE  = "create"
  VPRM = "view_perms"
  GPRM = "set_perms"

  ROLES = {
    "Image Administrator"    => [false, {PoolFamily   => [VIEW, USE] }],
    "Administrator"          => [false, {PoolFamily   => [VIEW,USE,MOD,CRE,VPRM,GPRM]}]
  }

  def self.up
    # This is meant to be an incremental update for existing installs, so if this is a fresh install,
    # bail out -- db:seeds will take care of this for us:
    return if Role.count == 0

    ROLES.each do |role_name, role_def|
      Role.transaction do
        role = Role.find_or_initialize_by_name(role_name)
        role.update_attributes({:name => role_name, :scope => BasePermissionObject.name, :assign_to_owner => role_def[0]})
        role.save!
        role_def[1].each do |priv_type, priv_actions|
          priv_actions.each do |action|
            if Privilege.where(:role_id => role.id, :target_type => priv_type.name, :action => action).empty?
              Privilege.create!(:role => role, :target_type => priv_type.name,
                                :action => action)
            end
          end
        end
      end
    end
  end

  def self.down
  end
end
