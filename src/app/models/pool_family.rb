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
# Schema version: 20110603204130
#
# Table name: pool_families
#
#  id           :integer         not null, primary key
#  name         :string(255)     not null
#  description  :string(255)
#  lock_version :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#  quota_id     :integer
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class PoolFamily < ActiveRecord::Base
  include PermissionedObject
  DEFAULT_POOL_FAMILY_KEY = "default_pool_family"

  has_many :pools,  :dependent => :destroy
  belongs_to :quota, :dependent => :destroy
  accepts_nested_attributes_for :quota
  has_and_belongs_to_many :provider_accounts
  has_many :permissions, :as => :permission_object, :dependent => :destroy

  validates_length_of :name, :maximum => 255
  validates_format_of :name, :with => /^[\w -]*$/n, :message => "must only contain: numbers, letters, spaces, '_' and '-'"

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :quota

  before_destroy :destroyable?

  def self.default
    MetadataObject.lookup(DEFAULT_POOL_FAMILY_KEY)
  end

  def set_as_default
    MetadataObject.set(DEFAULT_POOL_FAMILY_KEY, self)
  end

  def destroyable?
    # A PoolFamily is destroyable unless it is the default PoolFamily
    self != PoolFamily.default
  end

  def enabled?
    provider_accounts.blank? or provider_accounts.any? {|acc| acc.enabled?}
  end
end
