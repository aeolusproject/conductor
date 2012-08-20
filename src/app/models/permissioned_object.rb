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

  def has_privilege(permission_session, user, action, target_type=nil)
    return false if permission_session.nil? or user.nil? or action.nil?
    target_type = self.class.default_privilege_target_type if target_type.nil?
    if derived_permissions.includes(:role => :privileges,
                                    :entity => :session_entities).where(
      ["session_entities.user_id=:user and
        session_entities.permission_session_id=:permission_session_id and
        privileges.target_type=:target_type and
        privileges.action=:action",
        { :user => user.id,
          :permission_session_id => permission_session.id,
          :target_type => target_type.name,
          :action => action}]).any?
      return true
    else
      BasePermissionObject.general_permission_scope.permissions.
        includes(:role => :privileges,
                 :entity => :session_entities).where(
      ["session_entities.user_id=:user and
        session_entities.permission_session_id=:permission_session_id and
        privileges.target_type=:target_type and
        privileges.action=:action",
        { :user => user.id,
          :permission_session_id => permission_session,
          :target_type => target_type.name,
          :action => action}]).any?
    end
  end

  # Returns the list of objects to check for permissions on -- by default
  # this is empty (we don't denormalize Global permissions as they're
  # handled as a separate case.)
  def perm_ancestors
    []
  end
  # Returns the list of objects to generate derived permissions for
  # -- by default just this object
  def derived_subtree(role = nil)
    [self]
  end
  # on obj creation, set inherited permissions for new object
  def update_derived_permissions_for_ancestors
    # for create hook this should normally be empty
    old_derived_permissions = Hash[derived_permissions.map{|p| [p.permission.id,p]}]
    perm_ancestors.each do |perm_obj|
      perm_obj.permissions.each do |permission|
        if permission.role.privilege_target_match(self.class.default_privilege_target_type)
          unless old_derived_permissions.delete(permission.id)
            derived_permissions.create(:entity_id => permission.entity_id,
                                       :role_id => permission.role_id,
                                       :permission => permission)
          end
        end
      end
    end
    # anything remaining in old_derived_permissions should be removed,
    # as would be expected if this hook is triggered by removing a
    # catalog entry for a deployable
    old_derived_permissions.each do |id, derived_perm|
      derived_perm.destroy
    end
    #reload
  end
  # assign owner role so that the creating user has permissions on the object
  # Any roles defined on default_privilege_target_type with assign_to_owner==true
  # will be assigned to the passed-in user on this object
  def assign_owner_roles(user)
    roles = Role.find(:all, :conditions => ["assign_to_owner =:assign and scope=:scope",
                                            { :assign => true,
                                              :scope => self.class.default_privilege_target_type.name}])
    roles.each do |role|
      Permission.create!(:role => role, :entity => user.entity,
                         :permission_object => self)
    end
    self.reload
  end

  # Any methods here will be able to use the context of the
  # ActiveRecord model the module is included in.
  def self.included(base)
    base.class_eval do
      after_create :update_derived_permissions_for_ancestors

      # Returns the list of privilege target types that are relevant for
      # permission checking purposes. This is used in setting derived
      # permissions -- there's no need to create denormalized permissions
      # for a role which only grants Provider privileges on a Pool
      # object. By default, this is just the current object's type
      def self.active_privilege_target_types
        [self.default_privilege_target_type] + self.additional_privilege_target_types
      end
      def self.additional_privilege_target_types
        []
      end
      def self.default_privilege_target_type
        self
      end
      def self.list_for_user(permission_session, user, action,
                             target_type=self.default_privilege_target_type)
        if permission_session.nil? or user.nil? or action.nil? or target_type.nil?
          return where("1=0")
        end
        if BasePermissionObject.general_permission_scope.
            has_privilege(permission_session, user, action, target_type)
          scoped
        else
          includes([:derived_permissions => {:role => :privileges,
                                             :entity => :session_entities}]).
            where("session_entities.user_id=:user and
                   session_entities.permission_session_id=:permission_session_id and
                   privileges.target_type=:target_type and
                   privileges.action=:action",
                  {:user => user.id,
                   :permission_session_id => permission_session.id,
                   :target_type => target_type.name,
                   :action => action})
        end
      end
    end
  end

end
