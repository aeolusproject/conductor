# == Schema Information
# Schema version: 20110207110131
#
# Table name: realms
#
#  id           :integer         not null, primary key
#  external_key :string(255)     not null
#  name         :string(1024)    not null
#  provider_id  :integer
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

class Realm < ActiveRecord::Base
  has_many :instances
  belongs_to :provider
  named_scope :frontend, :conditions => { :provider_id => nil }

  has_and_belongs_to_many :frontend_realms,
                          :class_name => "Realm",
                          :join_table => "realm_map",
                          :foreign_key => "backend_realm_id",
                          :association_foreign_key => "frontend_realm_id"

  has_and_belongs_to_many :backend_realms,
                          :class_name => "Realm",
                          :join_table => "realm_map",
                          :foreign_key => "frontend_realm_id",
                          :association_foreign_key => "backend_realm_id"

  validates_presence_of :external_key
  validates_uniqueness_of :external_key, :scope => :provider_id

  validates_presence_of :name

  protected
  def validate
    if provider.nil? and !frontend_realms.empty?
      errors.add(:frontend_realms, "Frontend realms are allowed for backend realms only.")
    end


    if !provider.nil? and !backend_realms.empty?
      errors.add(:backend_realms, "Backend realms are allowed for frontend realms only.")
    end

    frontend_realms.each do |frealm|
      if name != frealm.name
        errors.add(:realms, "Frontend realm must have the same name as the appropriate backend realm.")
      end
      if external_key != frealm.external_key
        errors.add(:realms, "Frontend realm must have the same external key as the appropriate backend realm.")
      end
    end
    backend_realms.each do |brealm|
      if name != brealm.name
        errors.add(:realms, "Frontend realm must have the same name as the appropriate backend realm.")
      end
      if external_key != brealm.external_key
        errors.add(:realms, "Frontend realm must have the same external key as the appropriate backend realm.")
      end
    end
  end

  AGGREGATOR_REALM_PROVIDER_DELIMITER = ":"
  AGGREGATOR_REALM_ACCOUNT_DELIMITER = "/"
end
