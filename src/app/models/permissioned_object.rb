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
