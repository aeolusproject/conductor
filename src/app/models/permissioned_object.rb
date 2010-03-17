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
  def can_view_perms(user)
    has_privilege(user, Privilege::PERM_VIEW)
  end
  def can_set_perms(user)
    has_privilege(user, Privilege::PERM_SET)
  end

  def can_view_instances(user)
    has_privilege(user, Privilege::INSTANCE_VIEW)
  end
  def can_modify_instances(user)
    has_privilege(user, Privilege::INSTANCE_MODIFY)
  end
  def can_control_instances(user)
    has_privilege(user, Privilege::INSTANCE_CONTROL)
  end

  def can_view_stats(user)
    has_privilege(user, Privilege::STATS_VIEW)
  end

  def can_view_accounts(user)
    has_privilege(user, Privilege::ACCOUNT_VIEW)
  end
  def can_modify_accounts(user)
    has_privilege(user, Privilege::ACCOUNT_MODIFY)
  end

  def can_view_pools(user)
    has_privilege(user, Privilege::POOL_VIEW)
  end
  def can_modify_pools(user)
    has_privilege(user, Privilege::POOL_MODIFY)
  end

  def can_view_quotas(user)
    has_privilege(user, Privilege::QUOTA_VIEW)
  end
  def can_modify_quotas(user)
    has_privilege(user, Privilege::QUOTA_MODIFY)
  end

  def can_view_providers(user)
    has_privilege(user, Privilege::PROVIDER_VIEW)
  end
  def can_modify_providers(user)
    has_privilege(user, Privilege::PROVIDER_MODIFY)
  end

  def can_view_users(user)
    has_privilege(user, Privilege::USER_VIEW)
  end
  def can_modify_users(user)
    has_privilege(user, Privilege::USER_MODIFY)
  end

  def has_privilege(user, privilege)
    permissions.find(:first, :include => [:role => :privileges],
                     :conditions => ["permissions.user_id=:user and
                                      privileges.name=:priv",
                                     { :user => user.id,
                                       :priv => privilege }])
  end

  # Any methods here will be able to use the context of the
  # ActiveRecord model the module is included in.
  def self.included(base)
    base.class_eval do
      def self.list_for_user(user, privilege)
        if BasePortalObject.general_permission_scope.has_privilege(user, privilege)
          all
        else
          find(:all, :include => {:permissions => {:role => :privileges}},
               :conditions => ["permissions.user_id=:user and
                                privileges.name=:priv",
                               {:user => user.id,
                                :priv => privilege }])
        end
      end
    end
  end

end
