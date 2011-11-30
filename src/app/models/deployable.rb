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

class Deployable < ActiveRecord::Base
  include PermissionedObject

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 1024

  validates_presence_of :xml
  validate :valid_deployable_xml?

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :catalog_entries
  has_many :catalogs, :through => :catalog_entries

  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  after_create "assign_owner_roles(owner)"

  def valid_deployable_xml?
    deployable_xml = DeployableXML.new(xml)
    unless deployable_xml.validate!
      errors.add(:xml, I18n.t('catalog_entries.flash.warning.not_valid'))
    end
  end

  # Fetch the deployable contained at :url
  def fetch_deployable
    begin
      DeployableXML.new(xml)
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
      return images.compact.uniq
    end
  end

  def fetch_image_uuids
    deployable = fetch_deployable
    deployable.image_uuids unless deployable.nil?
  end

  def hw_profile_for_image(image_id)
    fetch_deployable.assemblies.each do |as|
      if as.image_id == image_id
       return HardwareProfile.find_by_name(as.hwp)
      end
    end
  end

  #method used with uploading deployable xml in catalog_entries#new
  def xml=(data)
    #for new
    if data.instance_variables.include?("@original_filename") && data.instance_variables.include?("@tempfile")
      write_attribute :xml_filename, data.original_filename
      write_attribute :xml, data.tempfile.read
    #for update or new from_url
    else
      write_attribute :xml, data
    end
  end

  def set_from_image(image_id, hw_profile)
    image = Aeolus::Image::Warehouse::Image.find(image_id)
    doc = Nokogiri::XML ''
    doc.root = doc.create_element('deployable', :name => image.name)
    description = doc.create_element('description')
    doc.root << description
    assemblies = doc.create_element('assemblies')
    doc.root << assemblies
    assembly = doc.create_element('assembly', :name => image.name, :hwp => hw_profile.name)
    assemblies << assembly
    img = doc.create_element('image', :id => image.uuid)
    assembly << img

    self.description = ''
    self.xml = doc.to_s
    self.xml_filename = image.name
    self.name = image.name
  end

  #get details of image for deployable#show
  def get_image_details
    stored_xml = Nokogiri::XML(xml)
    result_array ||= []
    stored_xml.xpath("//assembly").each do |assembly|
      if assembly.attr('name')
        assembly_hash ||= {:name => assembly.attr('name')}
      else
        assembly_hash ||= {:error_name => I18n.t('deployables.error.attribute_not_exist')}
      end
      if assembly.attr('hwp')
        hwp_name = stored_xml.xpath("//assembly").attr('hwp').value
        hwp = HardwareProfile.find_by_name(hwp_name)
        if hwp
          assembly_hash[:hwp] = {:name => hwp_name}
          assembly_hash[:hwp][:hdd] = hwp.storage.value
          assembly_hash[:hwp][:ram] = hwp.memory.value
          assembly_hash[:hwp][:arch] = hwp.architecture.value
        else
          assembly_hash[:error_hwp] = I18n.t('deployables.error.hwp_not_exists', :name => hwp_name)
        end
      else
        assembly_hash[:error_hwp] = I18n.t('deployables.error.attribute_not_exist')
      end
      result_array << assembly_hash
    end
    #returned value [{:name => 'assembly1',{:hwp => {...}}, {:error => "msg"}, {assembly3} ..]
    result_array
  end
end
