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

class Deployable < ActiveRecord::Base
  class << self
    include CommonFilterMethods
  end


  include PermissionedObject

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 1024

  validates_presence_of :xml
  validate :valid_deployable_xml?, :if => Proc.new { |deployable| !deployable.xml.blank? }

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :catalog_entries, :dependent => :destroy
  has_many :catalogs, :through => :catalog_entries

  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  after_create "assign_owner_roles(owner)"

  PRESET_FILTERS_OPTIONS = []

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
    uuids = fetch_image_uuids || []
    uuids.map { |uuid| Aeolus::Image::Warehouse::Image.find(uuid) }
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
    deployable_xml = DeployableXML.new(xml)
    assemblies_array ||= []
    deployable_xml.assemblies.each do |assembly|
      assembly_hash ||= {:name => assembly.name}
      assembly_hash[:image_uuid] = assembly.image_id
      assembly_hash[:images_count] = assembly.image.count
      if assembly.hwp
        hwp_name = assembly.hwp
        hwp = HardwareProfile.find_by_name(hwp_name)
        if hwp
          assembly_hash[:hwp_name] = hwp.name
          assembly_hash[:hwp_hdd] = hwp.storage.value
          assembly_hash[:hwp_ram] = hwp.memory.value
          assembly_hash[:hwp_arch] = hwp.architecture.value
        else
          assembly_hash[:error_hwp] = I18n.t('deployables.error.hwp_not_exists', :name => hwp_name)
        end
      else
        assembly_hash[:error_hwp] = I18n.t('deployables.error.attribute_not_exist')
      end
      assemblies_array << assembly_hash
    end
    assemblies_array
  end

  def build_status(images, account)
    image_statuses = images.map { |i| image_status(i, account) }
    return :not_built if image_statuses.any? { |status| status == :not_built }
    return :building if image_statuses.any? { |status| status == :building }
    return :pushing if image_statuses.any? { |status| status == :pushing }
    return :not_pushed if image_statuses.any? { |status| status == :not_pushed }
    :pushed
  end

  def image_status(image, account)
    build = image.latest_pushed_or_unpushed_build
    target = account.provider.provider_type.deltacloud_driver
    return :not_built unless build

    builder = Aeolus::Image::Factory::Builder.first
    return :building if builder.find_active_build(build.id, target)

    target_image = build.target_images.find { |ti| ti.target == target }
    return :not_built unless target_image

    return :pushing if builder.find_active_push(target_image.id,
                                                account.provider.name,
                                                account.credentials_hash["username"])

    provider_image = target_image.find_provider_image_by_provider_and_account(
        account.provider.name, account.warehouse_id).first
    return :not_pushed unless provider_image
    :pushed
  end

  def build_missing(images, accounts)
    targets = accounts.map { |acc| acc.provider.provider_type.deltacloud_driver }.uniq.join(',')
    images.each do |image|
      factory_image = Aeolus::Image::Factory::Image.new(:id => image.id)
      factory_image.targets = targets
      factory_image.template = image.template
      factory_image.save!
    end
  end

  def push_missing(images, accounts)
    images.each do |image|
      accounts.each do |account|
        if image_status(image, account) == :not_pushed
          target = account.provider.provider_type.deltacloud_driver
          build = image.latest_pushed_or_unpushed_build
          target_image = build.target_images.find { |ti| ti.target == target }
          provider_image = Aeolus::Image::Factory::ProviderImage.new(
            :provider => account.provider.name,
            :credentials => account.to_xml(:with_credentials => true),
            :image_id => image.uuid,
            :build_id => build.uuid,
            :target_image_id => target_image.uuid
          )
          provider_image.save!
        end
      end
    end
  end

  private

  def self.apply_search_filter(search)
    if search
      where("name ILIKE :search", :search => "%#{search}%")
    else
      scoped
    end
  end
end
