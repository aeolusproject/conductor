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

module PermissionedObject

  def has_privilege(user, action, target_type=nil)
    return false if user.nil? or action.nil?
    target_type = self.class.default_privilege_target_type if target_type.nil?
    object_list.each do |obj|
      return true if obj and obj.permissions.find(:first,
                                          :include => [:role => :privileges],
                                          :conditions =>
                                          ["permissions.user_id=:user and
                                            privileges.target_type=:target_type and
                                            privileges.action=:action",
                                           { :user => user.id,
                                             :target_type => target_type.name,
                                             :action => action}])
    end
    return false
  end

  # Returns the list of objects to check for permissions on -- by default
  # this object plus the Base permission object
  def object_list
    [self, BasePermissionObject.general_permission_scope]
  end

  # assign owner role so that the creating user has permissions on the object
  # Any roles defined on default_privilege_target_type with assign_to_owner==true
  # will be assigned to the passed-in user on this object
  def assign_owner_roles(user)
    roles = Role.find(:all, :conditions => ["assign_to_owner =:assign and scope=:scope",
                                            { :assign => true,
                                              :scope => self.class.default_privilege_target_type.name}])
    roles.each do |role|
      Permission.create!(:role => role, :user => user, :permission_object => self)
    end
  end

  # Any methods here will be able to use the context of the
  # ActiveRecord model the module is included in.
  def self.included(base)
    base.class_eval do
      def self.default_privilege_target_type
        self.name.constantize
      end
      def self.list_for_user_include
        [{:permissions => {:role => :privileges}}]
      end
      def self.list_for_user_conditions
        "permissions.user_id=:user and
         privileges.target_type=:target_type and
         privileges.action=:action"
      end
      def self.list_for_user(user, action, target_type=self.default_privilege_target_type)
        return where("1=0") if user.nil? or action.nil? or target_type.nil?
        if BasePermissionObject.general_permission_scope.has_privilege(user, action, target_type)
          scoped
        else
          include_clause = self.list_for_user_include
          conditions_hash = {:user => user.id, :target_type => target_type.name, :action => action}
          conditions_str = self.list_for_user_conditions
          includes(include_clause).where(conditions_str, conditions_hash)
        end
      end
    end
  end

end
