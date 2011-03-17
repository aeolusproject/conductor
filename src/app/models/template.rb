# == Schema Information
# Schema version: 20110207110131
#
# Table name: templates
#
#  id               :integer         not null, primary key
#  uuid             :string(255)     not null
#  xml              :binary          not null
#  uri              :string(255)
#  name             :string(255)
#  platform         :string(255)
#  platform_version :string(255)
#  architecture     :string(255)
#  summary          :text
#  complete         :boolean
#  uploaded         :boolean
#  imported         :boolean
#  images_count     :integer
#  created_at       :datetime
#  updated_at       :datetime
#

require 'util/image_descriptor_xml'
require 'typhoeus'

class Template < ActiveRecord::Base
  include PermissionedObject
  include ImageWarehouseObject

  searchable do
    text :name, :as => :code_substring
    text :platform, :as => :code_substring
    text :platform_version, :as => :code_substring
    text :architecture, :as => :code_substring
    text :summary, :as => :code_substring
  end

  has_many :images, :dependent => :destroy
  has_many :instances
  has_and_belongs_to_many :assemblies
  before_validation :generate_uuid
  before_save [:update_xml, :upload]
  before_destroy [:no_instances?, :delete_in_warehouse]

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  validates_presence_of :uuid
  validates_uniqueness_of :uuid
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of   :name, :maximum => 255
  validates_presence_of :platform
  validates_presence_of :platform_version
  validates_presence_of :architecture

  def no_instances?
    unless instances.empty?
      errors.add(:base, 'There are instances for this template.')
      return false
    end

    true
  end

  def update_xml
    xml.name = self.name
    xml.description = self.summary
    platform = {}
    platform['name'] = self.platform.capitalize
    platform['version'] = self.platform_version
    platform['arch'] = self.architecture
    xml.platform = platform
    write_attribute(:xml, xml.to_xml)
  end

  def providers
    # TODO: rewrite cleanly
    ProviderImage.all(
      :include => [:image, :provider],
      :conditions => {:images => {:template_id => self.id}}
    ).map {|p| p.provider}
  end

  def self.find_or_create(id)
    id ? Template.find(id) : Template.new
  end

  def set_complete
    update_attributes(:complete => true, :uploaded => false)
  end

  def platforms
    @platforms ||= YAML.load_file("#{RAILS_ROOT}/config/image_descriptor_platform_repositories.yml")
  end

  def add_packages(packages)
    packages.to_a.each {|pkg| xml.add_package(pkg)}
  end

  def add_groups(groups)
    groups.to_a.each {|pkg| xml.add_group(pkg)}
  end

  def add_software(packages, groups)
    add_packages(packages)
    add_groups(groups)
  end

  # sets platform info from predefined platform list
  def platform=(plat)
    write_attribute(:platform, plat)
    self.platform_version = platforms[plat]['version'].to_s
    self.architecture = platforms[plat]['architecture']
  end

  # sets platform info from hash (used when importing images)
  def platform_hash=(plat)
    write_attribute(:platform, plat[:platform])
    self.platform_version = plat[:version]
    self.architecture = plat[:architecture]
  end

  # packages and groups are virtual attributes
  def packages
    xml.packages
  end

  def packages=(packages)
    xml.clear_packages
    packages.to_a.each {|pkg| xml.add_package(pkg)}
  end

  def groups
    xml.groups
  end

  def groups=(groups)
    xml.clear_groups
    groups.to_a.each {|group| xml.add_group(group)}
  end

  def warehouse_body
    self.xml.to_xml
  end

  def warehouse_bucket
    'templates'
  end

  def warehouse_url
    baseurl = YAML.load_file("#{RAILS_ROOT}/config/image_warehouse.yml")['baseurl'] + "/templates/"
    self.uuid ? baseurl + self.uuid : baseurl
  end
end
