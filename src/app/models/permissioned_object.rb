#
# Copyright (C) 2010 Red Hat, Inc.
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
module PermissionedObject

  def has_privilege(user, action, target_type=nil)
    return false if user.nil? or action.nil?
    target_type = self.class.default_privilege_target_type if target_type.nil?
    object_list.each do |obj|
      return true if obj.permissions.find(:first,
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
      # :conditions in hash must match form ["foo=:param and ...", {:param => value}]
      def self.list_for_user(user, action, find_hash={})
        target_type = find_hash.fetch(:target_type, self.default_privilege_target_type)
        query_include = find_hash[:include]
        query_order = find_hash[:order]
        query_conditions = find_hash[:conditions]
        return [] if user.nil? or action.nil? or target_type.nil?
        if BasePermissionObject.general_permission_scope.has_privilege(user,
                                                                       action,
                                                                       target_type)
          find(:all, :include => query_include,
                     :order => query_order,
                     :conditions => query_conditions)
        else
          include_clause = self.list_for_user_include
          if query_include.is_a?(Array)
            include_clause += query_include
          elsif !query_include.nil?
            include_clause << query_include
          end
          conditions_hash = {:user => user.id,
                             :target_type => target_type.name,
                             :action => action}
          if query_conditions.nil?
            conditions_str = self.list_for_user_conditions
          else
            conditions_str = "(#{self.list_for_user_include}) and (#{query_conditions[0]})"
            conditions_hash.merge!(query_conditions[1]) { |key, h1, h2| h1 }
          end
          find(:all, :include => include_clause,
               :conditions => [conditions_str, conditions_hash],
               :order => query_order)
        end
      end
    end
  end

end
