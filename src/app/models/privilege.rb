#
# Copyright (C) 2009 Red Hat, Inc.
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

class Privilege < ActiveRecord::Base
  has_and_belongs_to_many :roles

  validates_presence_of :name
  validates_uniqueness_of :name

  #default privileges
  PERM_SET          = "set_perms"         # can create/modify/delete permission
                                          # records on this object
  PERM_VIEW         = "view_perms"        # can view permission records on this
                                          # object

  # instance privileges normally checked at the pool level, although
  # instance-specific overrides could be a future enhancement.
  INSTANCE_MODIFY   = "instance_modify"   # can create, modify, delete, or
                                          # control (start, stop, etc) instances
  INSTANCE_CONTROL  = "instance_control"  # can control (start, stop, etc)
                                          # instances
  INSTANCE_VIEW     = "instance_view"     # can view instance metadata
  # do we need a separate "connect" privilege?

  # stats privileges normally checked at the pool level, although
  # instance-specific overrides could be a future enhancement.
  STATS_VIEW        = "stats_view"        # can view monitoring data for
                                          # instances

  # to create(i.e. import) an account on a provider (but not added to
  # a pool) needs ACCOUNT_MODIFY on the provider.
  # to add a new provider account (i.e. import) to a pool needs
  # ACCOUNT_ADD on  the pool
  # to add an existing provider account to a pool needs ACCOUNT_ADD
  # on the pool _and_ ACCOUNT_ADD on the account.
  ACCOUNT_MODIFY    = "account_modify"    # can create or modify cloud accounts
  ACCOUNT_VIEW      = "account_view"      # can view cloud accounts
  ACCOUNT_ADD       = "account_add"       # can add an account to a pool

  # pool privileges normally checked at the provider level
  # (and at the account level for choosing which accounts are visible on the
  # new pool form), although
  # pool-specific overrides could be a future enhancement.
  POOL_MODIFY       = "pool_modify"       # can create or modify a pool
  POOL_VIEW         = "pool_view"         # can view a pool

  # quota privileges normally checked at the pool or account level,
  # depending on which quota level we're dealing with
  # (account level for cloud-imposed quota, pool level for aggregator quota)
  QUOTA_MODIFY      = "quota_modify"      # can create or modify a quota
  QUOTA_VIEW        = "quota_view"        # can view a quota

  # provider privileges normally checked at the provider level, although
  # 'new provider' action requires this privilege at the SystemPermission level
  PROVIDER_MODIFY   = "provider_modify"   # can create or modify a provider
  PROVIDER_VIEW     = "provider_view"     # can view a provider

  # normally checked at the SystemPermission level
  USER_MODIFY       = "user_modify"       # can create a new user (other than
                                          # self-registration) or modify another
                                          # user's metadata (for admin-level
                                          # actions)
  USER_VIEW         = "user_view"         # can view a user's profile data

  FULL_PRIVILEGE_LIST = [PERM_SET, PERM_VIEW,
                         INSTANCE_MODIFY, INSTANCE_CONTROL, INSTANCE_VIEW,
                         STATS_VIEW,
                         ACCOUNT_MODIFY, ACCOUNT_ADD, ACCOUNT_VIEW,
                         POOL_MODIFY, POOL_VIEW,
                         QUOTA_MODIFY, QUOTA_VIEW,
                         PROVIDER_MODIFY, PROVIDER_VIEW,
                         USER_MODIFY, USER_VIEW]
end
