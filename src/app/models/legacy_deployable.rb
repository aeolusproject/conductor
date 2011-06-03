# == Schema Information
# Schema version: 20110207110131
#
# Table name: deployables
#
#  id           :integer         not null, primary key
#  name         :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  lock_version :integer         default(0)
#  uuid         :string(255)     not null
#  xml          :binary          not null
#  uri          :string(255)
#  summary      :text
#  uploaded     :boolean
#

#
# Copyright (C) 2011 Red Hat, Inc.
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

require 'sunspot_rails'
class LegacyDeployable < ActiveRecord::Base
  include PermissionedObject
  include ImageWarehouseObject
  searchable do
    text :name, :as => :code_substring
    text :summary, :as => :code_substring
  end

  has_and_belongs_to_many :assemblies
  has_many :deployments

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  after_create "assign_owner_roles(owner)"

  before_validation :generate_uuid
  before_save :update_xml

  validates_presence_of :uuid
  validates_uniqueness_of :uuid
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of   :name, :maximum => 255
  validates_presence_of :owner_id

  before_destroy :destroyable?

  def self.default_privilege_target_type
    Template
  end

  def update_xml
    xml.name = self.name
    xml.description = self.summary
    write_attribute(:xml, xml.to_xml)
  end

  def self.find_or_create(id)
    id ? LegacyDeployable.find(id) : LegacyDeployable.new
  end

  def destroyable?
    deployments.all? {|d| d.destroyable? }
  end

  def launchable?
    return false if assemblies.empty?
    assemblies.each do |a|
      return false if a.templates.empty?
      # TODO: should we check if there is an uploaded image for each template in
      # assembly?
    end
    return true
  end
end
