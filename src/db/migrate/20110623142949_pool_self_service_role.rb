#
# Copyright (C) 2011 Red Hat, Inc.
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

class PoolSelfServiceRole < ActiveRecord::Migration
  VIEW = "view"
  CRE  = "create"
  ROLE_NAME = "Pool Global User"
  ROLE_DEF = [false, {Pool         => [VIEW],
                      Instance     => [             CRE],
                      Deployment   => [             CRE],
                      Quota        => [VIEW]}]

  def self.up
    return if Role.all.empty?

    Role.transaction do
      role = Role.find_or_initialize_by_name(ROLE_NAME)
      role.update_attributes({:name => ROLE_NAME, :scope => BasePermissionObject.name,
                                :assign_to_owner => ROLE_DEF[0]})
      role.privileges = {}
      role.save!
      ROLE_DEF[1].each do |priv_type, priv_actions|
        priv_actions.each do |action|
          Privilege.create!(:role => role, :target_type => priv_type.name,
                            :action => action)
        end
      end

      MetadataObject.transaction do
        settings = {
          "self_service_default_pool_global_user_obj" => BasePermissionObject.general_permission_scope,
          "self_service_default_pool_global_user_role" => Role.find_by_name("Pool Global User"),
          "self_service_perms_list" => "[self_service_default_pool,self_service_default_role], [self_service_default_suggested_deployable_obj,self_service_default_suggested_deployable_role], [self_service_default_pool_global_user_obj,self_service_default_pool_global_user_role]" }
        settings.each_pair { |key, value| MetadataObject.set(key, value) }
      end

      Permission.transaction do
        User.all.each do |user|
          default_obj = MetadataObject.lookup("self_service_default_pool_global_user_obj")
          default_role = MetadataObject.lookup("self_service_default_pool_global_user_role")
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
