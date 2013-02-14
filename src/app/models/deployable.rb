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

require 'util/conductor'

class Deployable < ActiveRecord::Base
  class << self
    include CommonFilterMethods
  end


  include PermissionedObject

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 1024

  validates_presence_of :xml
  validate :validate_deployable_xml, :if => Proc.new {|deployable|
                                              !deployable.xml.blank? }

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"

  has_many :catalog_entries, :dependent => :destroy
  has_many :catalogs, :through => :catalog_entries
  belongs_to :pool_family

  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  after_create "assign_owner_roles(owner)"
  before_create :set_pool_family

  scope :without_catalog, lambda {
    deployable_ids_in_association = CatalogEntry.select(:deployable_id).map(&:deployable_id)
    where('id NOT IN (?)', deployable_ids_in_association)
  }

  PRESET_FILTERS_OPTIONS = []

  def perm_ancestors
    super + catalogs + catalogs.collect{|c| c.pool}.uniq + [pool_family]
  end

  def validate_deployable_xml
    begin
      deployable_xml = DeployableXML.new(xml)
      if !deployable_xml.validate!
        errors.add(:xml, _('file contains syntax errors'))
      elsif !deployable_xml.unique_assembly_names?
        errors.add(:xml, _('must contain unique Assembly names'))
      end
      validate_cycles_in_deployable_xml(deployable_xml)
      validate_references_in_deployable_xml(deployable_xml)
    rescue Nokogiri::XML::SyntaxError => e
      errors.add(:base, _('seems to be not valid Deployable XML: %s') % "#{e.message}")
    end
  end

  def validate_cycles_in_deployable_xml(deployable_xml)
    deployable_xml.dependency_graph.cycles.each do |cycle|
      cycle_str = cycle.map do |node|
        str = node[:assembly].to_s
        str << "[#{node[:service]}]" if node[:service].present?
        str
      end.join(' -> ')
      errors.add(:xml,
                 _('Contains cyclic reference between following Assemblies or services: %s') % cycle_str)
    end
  end

  def validate_references_in_deployable_xml(deployable_xml)
    deployable_xml.dependency_graph.not_existing_references.each do |reference|
      locale_params = {:from_assembly => reference[:assembly],
                       :from_service => reference[:service],
                       :from_param => reference[:reference][:from_param],
                       :to_param => reference[:reference][:param],
                       :to_assembly => reference[:reference][:assembly],
                       :to_service => reference[:reference][:service]}
      if reference[:no_return_param]
        errors.add(:xml,
                   _('Assembly %{from_assembly}, service %{from_service}, parameter %{from_param} references param %{to_param} which is not returned by Assembly %{to_assembly}') % locale_params)
      elsif reference[:reference][:service]
        errors.add(:xml,
                   _('Assembly %{from_assembly}, service %{from_service}, parameter %{from_param} references not existing Assembly %{to_assembly}, service %{to_service}') % locale_params)
      else
        errors.add(:xml,
                   _('Assembly %{from_assembly}, service %{from_service}, parameter %{from_param} references not existing Assembly %{to_assembly}') % locale_params)
      end
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

  def fetch_unique_images
    uuids = fetch_image_uuids || []
    uniq_uuids = uuids.uniq
    result_hash = {}
    uniq_uuids.each do |uuid|
      result_hash[uuid] = { :image => Tim::BaseImage.find_by_uuid(uuid), :count => uuids.count(uuid)}
    end
    result_hash
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
    if data.is_a?(ActionDispatch::Http::UploadedFile)
      write_attribute :xml_filename, data.original_filename
      write_attribute :xml, data.tempfile.read
    #for update or new from_url
    else
      write_attribute :xml, data
    end
  end

  def set_from_image(image_id, name, hw_profile)
    image = Tim::BaseImage.find(image_id)
    doc = Nokogiri::XML ''
    doc.root = doc.create_element('deployable', :version => DeployableXML.version, :name => name)
    description = doc.create_element('description')
    doc.root << description
    assemblies = doc.create_element('assemblies')
    doc.root << assemblies
    assembly = doc.create_element('assembly', :name => image.name.gsub(/[^a-zA-Z0-9]+/, '-'), :hwp => hw_profile.name)
    assemblies << assembly
    img = doc.create_element('image', :id => image.uuid)
    assembly << img

    self.description = ''
    self.xml = doc.to_s
    self.xml_filename = name
  end

  #get details of image for deployable#show
  def get_image_details
    deployable_xml = DeployableXML.new(xml)
    uuids = deployable_xml.image_uuids
    images = []
    missing_images = []
    assemblies_array ||= []
    deployable_errors ||= []
    deployable_xml.assemblies.each do |assembly|
      assembly_hash = {}

      begin
        image = Tim::BaseImage.find_by_uuid(assembly.image_id)
      rescue Exception => e
        error = humanize_error(e.message)
      end

      if !error.nil?
        missing_images << assembly.image_id
        deployable_errors << error
      elsif image.nil?
        missing_images << assembly.image_id
        deployable_errors << _('%s: Image (UUID: %s) doesn\'t exist') % [assembly.name, assembly.image_id]
      else
        if image.pool_family != pool_family
          deployable_errors << _('The Deployable \'%s\' contains an image (UUID %s) in the wrong Environment (\'%s\' should be \'%s\') and cannot be used.') % [name, assembly.image_id, image.pool_family.name, pool_family.name]
        end
        images << image
        assembly_hash[:build_and_target_uuids] = get_build_and_target_uuids(image)
      end
      assembly_hash[:name] = assembly.name
      assembly_hash[:image_uuid] = assembly.image_id
      assembly_hash[:images_count] = assembly.images_count
      if assembly.hwp
        hwp = HardwareProfile.find_by_name(assembly.hwp)
        if hwp
          assembly_hash[:hwp_name] = hwp.name
          assembly_hash[:hwp_hdd] = hwp.storage.value
          assembly_hash[:hwp_ram] = hwp.memory.value
          assembly_hash[:hwp_arch] = hwp.architecture.value
        else
          deployable_errors << "#{assembly_hash[:name]}: " + _('Hardware Profile %s, which is specified in XML, does not exist.') % assembly.hwp
        end
      else
        deployable_errors << "#{assembly_hash[:name]}: " + _('Some attribute(s) are missing in the XML. Please check the file.')
      end
      assemblies_array << assembly_hash
      # TODO: check_audrey_api_compatibility uses icicle object which is not
      # supported in Tim yet
      #audrey_error = check_audrey_api_compatibility(image, assembly)
      audrey_error = nil
      deployable_errors << "#{assembly_hash[:name]}: " + audrey_error if not audrey_error.nil?
    end
    [assemblies_array, images, missing_images, deployable_errors]
  end

  def build_status(images, account)
    begin
      pimgs = images.map { |i| i.last_provider_image(account) }
      return :pushing if pimgs.any? { |pimg| pimg && pimg.pushing? }
      return :pushed if pimgs.all? { |pimg| pimg && pimg.pushed? }
      :not_pushed
    rescue Exception => e
      error = humanize_error(e.message)
      return error
    end
  end

  def to_polymorphic_path_param(polymorphic_path_extras)
    catalog = catalogs.find(polymorphic_path_extras[:catalog_id]) if (polymorphic_path_extras.present? &&
        polymorphic_path_extras.has_key?(:catalog_id))
    [catalog, self]
  end

  def get_build_and_target_uuids(image)
    latest_build = image.last_built_image_version
    [image.uuid,
     (latest_build ? latest_build.uuid : nil),
     (latest_build ? latest_build.target_images.collect { |ti| ti.factory_id} : nil)]
  end

  def set_pool_family
    self[:pool_family_id] = catalogs.first.pool_family_id
  end

  def check_service_params_types
    warnings = []
    deployable_xml = DeployableXML.new(xml)
    deployable_xml.assemblies.each do |assembly|
      assembly.services.each do |service|
        service.parameters.each do |param|
          if param.type_warning
            warnings << I18n.translate("deployables.flash.warning.param_type_attr",
                                 :service_name => service.name,
                                 :param_name => param.name)
          end
        end
      end
    end
    warnings
  end

  #def check_audrey_api_compatibility(image, assembly)
  #  # get icicle for agent
  #  icicle_uuid = image.latest_pushed_or_unpushed_build.target_images.first.icicle rescue nil
  #  icicle = Aeolus::Image::Warehouse::Icicle.find(icicle_uuid) if icicle_uuid
  #  agent_v = icicle ? icicle.packages.find_all { |p| p =~ /aeolus-audrey-agent(.*)/ } : ""
  #  agent_v = agent_v.present? ? agent_v.first.split('-')[3] : ""

  #  # calculate audrey api version
  #  audrey_api_v = if agent_v >= "0.5.0"
  #                    1..2
  #                  elsif agent_v >= "0.4.0"
  #                    1..1
  #                  else 0
  #                  end

  #  # initalize compatibility
  #  audrey_api_compat = 1

  #  # do cs_compat
  #  ## All agents are compatible with all Config Servers right now
  #  ## so no need to check this right now
  #  ## this check should call the cs passing the agent_v and validating
  #  ## the response the CS sends back

  #  # audrey api version 2 added service references, lets check for any
  #  assembly.services.each do |service|
  #    service.parameters.each do |param|
  #      audrey_api_compat = 2 if param.reference_service
  #    end
  #  end

  #  if audrey_api_v != 0
  #    audrey_api_v.include?(audrey_api_compat) ? nil : _('The Deployable uses features not supported by the Audrey agent installed in the latest built image.')
  #  end
  #end

  private

  def self.apply_search_filter(search)
    if search
      where("lower(name) LIKE :search", :search => "%#{search.downcase}%")
    else
      scoped
    end
  end
end
