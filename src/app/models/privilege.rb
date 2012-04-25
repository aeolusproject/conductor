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

# == Schema Information
# Schema version: 20110207110131
#
# Table name: privileges
#
#  id           :integer         not null, primary key
#  role_id      :integer         not null
#  target_type  :string(255)     not null
#  action       :string(255)     not null
#  lock_version :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#

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
                             #   ProviderAccount: May add this account to PoolFamily


  ACTIONS = [ CREATE, MODIFY, USE, VIEW,
              PERM_SET, PERM_VIEW]
  TYPES   = { BasePermissionObject => [MODIFY, PERM_SET, PERM_VIEW],
              Pool => ACTIONS - [USE],
              PoolFamily => ACTIONS,
              Instance => ACTIONS,
              Deployment => ACTIONS,
              Deployable => ACTIONS,
              Quota => [VIEW, MODIFY],
              HardwareProfile => ACTIONS - [USE],
              Realm => ACTIONS - [VIEW],
              Provider => ACTIONS,
              ProviderAccount => ACTIONS,
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
  # Instance This Deployment or deployments within this Pool
  #   view        Can view
  #   use         Can perform lifecycle actions on and/or view console
  #   modify      Can modify
  #   create      Can create (within this Pool)
  #   view_perms  Can view permissions
  #   set_perms   Can set permissions (or can set instance permissions on this pool)
  #
  # Quota  The Pool/ProviderAccount/PoolFamily/User assigned the quota
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
  # ProviderAccount This ProviderAccount
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
