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

# == Schema Information
# Schema version: 20110207110131
#
# Table name: realm_backend_targets
#
#  id                     :integer         not null, primary key
#  realm_or_provider_id   :integer         not null
#  realm_or_provider_type :string(255)     not null
#  frontend_realm_id      :integer         not null
#

class RealmBackendTarget < ActiveRecord::Base
  belongs_to :frontend_realm
  belongs_to :realm_or_provider, :polymorphic =>true
  belongs_to :realm,  :class_name => 'Realm', :foreign_key => 'realm_or_provider_id'
  belongs_to :provider,  :class_name => 'Provider', :foreign_key => 'realm_or_provider_id'

  validates_uniqueness_of :frontend_realm_id, :scope => [:realm_or_provider_id, :realm_or_provider_type]
  validates_presence_of :realm_or_provider

  def target_realm
    (realm_or_provider_type == "Realm") ? realm : nil
  end

  def target_provider
    (realm_or_provider_type == "Realm") ? realm.provider : provider
  end
end
