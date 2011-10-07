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
#
# Table name: catalog_entries
#
#  id          :integer         not null, primary key
#  name        :string(1024)    not null
#  description :text            not null
#  url         :string(255)
#  owner_id    :integer
#  catalog_id  :integer         not null
#

class CatalogEntry < ActiveRecord::Base
  include PermissionedObject

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 1024
  validates_presence_of :url
  validates_format_of :url, :with => URI::regexp
  validates_presence_of :catalog

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  belongs_to :catalog
  after_create "assign_owner_roles(owner)"

  def accessible_and_valid_deployable_xml?(url)
    begin
      deployable_xml = fetch_deployable
      deployable_xml.validate!
      true
    rescue
      false
    end
  end

  # Fetch the deployable contained at :url
  def fetch_deployable
    begin
      DeployableXML.new(DeployableXML.import_xml_from_url(url))
    rescue
      return nil
    end
  end

  # Round up Catalog Entries, fetch their Deployables, and extract image UUIDs.
  def fetch_images
    images = []
    unless fetch_image_uuids.nil?
      fetch_image_uuids.each do |uuid|
        images << Aeolus::Image::Warehouse::Image.find(uuid)
      end
      images.compact.uniq
    end
  end

  def fetch_image_uuids
    deployable = fetch_deployable
    deployable.image_uuids unless deployable.nil?
  end

end
