# == Schema Information
# Schema version: 20110207110131
#
# Table name: frontend_realms
#
#  id           :integer         not null, primary key
#  name         :string(1024)    not null
#  lock_version :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#

#
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class FrontendRealm < ActiveRecord::Base
  has_many :realm_backend_targets
  has_many :instances

  # there is a problem with has_many through + polymophic in AR:
  # http://blog.hasmanythrough.com/2006/4/3/polymorphic-through
  # so we define explicitly backend_realms and backend_providers
  has_many :backend_realms, :through => :realm_backend_targets, :source => :realm, :conditions => "realm_backend_targets.realm_or_provider_type = 'Realm'"
  has_many :backend_providers, :through => :realm_backend_targets, :source => :provider, :conditions => "realm_backend_targets.realm_or_provider_type = 'Provider'"

  validates_presence_of :name
  validates_uniqueness_of :name
end
