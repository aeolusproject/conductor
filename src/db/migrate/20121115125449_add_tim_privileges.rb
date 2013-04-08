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

class AddTimPrivileges < ActiveRecord::Migration
  class Role < ActiveRecord::Base; end
  class Privilege < ActiveRecord::Base; end

  VIEW = "view"
  USE  = "use"
  MOD  = "modify"
  CRE  = "create"
  VPRM = "view_perms"
  GPRM = "set_perms"

  ROLES = %w(pool_family.image.admin pool_family.admin base.image.admin
             base.admin base.pool.admin)
  def self.up
    # This is meant to be an incremental update for existing installs, so if this is a fresh install,
    # bail out -- db:seeds will take care of this for us:
    return if Role.count == 0

    ROLES.each do |role_name|
      role = Role.find_by_name(role_name)
      next unless role
      [VIEW, USE, MOD, CRE, VPRM, GPRM].each do |action|
        Privilege.create!(:role => role, :target_type => Tim::BaseImage.name,
                          :action => action)
        Privilege.create!(:role => role, :target_type => Tim::Template.name,
                          :action => action)
      end
    end
  end

  def self.down
    ROLES.each do |role_name|
      role = Role.find_by_name(role_name)
      next unless role
      role.privileges.where(:target_type => Tim::Template.name).each do |priv|
        priv.destroy
      end
      role.privileges.where(:target_type => Tim::BaseImage.name).each do |priv|
        priv.destroy
      end
    end
  end
end
