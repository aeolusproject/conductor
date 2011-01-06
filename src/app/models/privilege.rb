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

  PERM_SET  = "set_perms"    # can create/modify/delete permission
                             # records on this object
  PERM_VIEW = "view_perms"   # can view permission records on this
                             # object
  CREATE    = "create"       # can create objects of this type here
  MODIFY    = "modify"       # can modify objects of this type here
  VIEW      = "view"         # can view objects of this type here
  USE       = "use"          # can use objects of this type here
                             # the meaning of 'use' is type-specific:
                             #   Template: add this template to an assembly
                             #   Assembly: add this assembly to a deployable
                             #   Deployable: choose this deployable to launch
                             #   Instance: may perform actions on this instance
                             #   Realm: may map this realm
                             #   CloudAccount: May add this account to PoolFamily


  ACTIONS = [ CREATE, MODIFY, USE, VIEW,
              PERM_SET, PERM_VIEW]
  TYPES   = { BasePermissionObject => [MODIFY, PERM_SET, PERM_VIEW],
              Template => ACTIONS,
              Pool => ACTIONS - [USE],
              PoolFamily => ACTIONS - [USE],
              Instance => ACTIONS,
              Quota => [VIEW, MODIFY],
              HardwareProfile => ACTIONS - [USE, VIEW],
              Realm => ACTIONS - [VIEW],
              Provider => ACTIONS - [USE],
              CloudAccount => ACTIONS,
              User => [ CREATE, MODIFY, VIEW] }

  belongs_to :role
  validates_presence_of :role_id
  validates_presence_of :target_type
  validates_presence_of :action
  validates_uniqueness_of :action, :scope => [:target_type, :role_id]

  # notes on available privilege action/type pairs. Format is:
  # Type          Scope
  #   Action      Notes (action defined on scope above unless specified)
  #
  # BasePermissionObject   the base perm object
  #   modify      Can modify system settings, etc.
  #   view_perms  Can view permissions
  #   set_perms   Can set permissions
  #
  # Template  This template/assembly/deployable or all T/A/D in this TADCollection
  #   view        Can view
  #   use         Can assign T/A/D to TAD collection;
  #                (if template) can add to assembly or can use to launch instance
  #                (if assembly) can add to deployable
  #                (if deployable) can use to launch deployment
  #                (if TAD Collection) not used
  #   modify      Can modify
  #   create      Can create (on BasePermissionObject)
  #   view_perms  Can view permissions
  #   set_perms   Can set permissions
  #
  # Pool This pool
  #   view        Can view
  #   modify      Can modify
  #   create      Can create (on BasePermissionObject)
  #   view_perms  Can view permissions
  #   set_perms   Can set permissions
  #
  # PoolFamily This PoolFamily
  #   view        Can view
  #   modify      Can modify
  #   create      Can create (on BasePermissionObject)
  #   view_perms  Can view permissions
  #   set_perms   Can set permissions
  #
  # Instance This Instance or instances within this Pool
  #   view        Can view
  #   use         Can perform lifecycle actions on and/or view console
  #   modify      Can modify
  #   create      Can create (within this Pool)
  #   view_perms  Can view permissions
  #   set_perms   Can set permissions (or can set instance permissions on this pool)
  #
  # Quota  The Pool/CloudAccount/PoolFamily/User assigned the quota
  #   view        Can view quota on this obj
  #   modify      Can edit quota on this obj
  #
  # HardwareProfile This HardwareProfile
  #   modify      (for Aeolus HWPs) Can modify
  #   create      Can create (on BasePermissionObject)
  #   view_perms  Can view permissions
  #   set_perms   Can set permissions
  #
  # Realm This Realm (or realms within this provider)
  #   use         (for provider Realm) can map realm or provider to aeolus realm
  #   modify      (for Aeolus realms) Can modify
  #   create      Can create (within this Pool)
  #   view_perms  Can view permissions
  #   set_perms   Can set permissions
  #
  # Provider This Provider
  #   view        Can view
  #   modify      Can modify
  #   create      Can create (on BasePermissionObject)
  #   view_perms  Can view permissions
  #   set_perms   Can set permissions
  #
  # CloudAccount This CloudAccount
  #   view        Can view
  #   use         Can map to PoolFamily
  #   modify      Can modify
  #   create      Can create (within this Provider)
  #   view_perms  Can view permissions
  #   set_perms   Can set permissions
  #
  # User This User (set on BasePermissionObject)
  #   view        Can view
  #   modify      Can modify
  #   create      Can create

end
