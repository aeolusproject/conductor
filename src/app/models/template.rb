require 'util/image_descriptor_xml'
require 'typhoeus'

class Template < ActiveRecord::Base
  has_many :images, :dependent => :destroy
  has_many :instances
  before_validation :generate_uuid
  before_save :update_xml
  before_destroy :no_instances?

  WAREHOUSE_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/image_warehouse.yml")

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

  def xml
    @xml ||= ImageDescriptorXML.new(self[:xml].to_s)
  end

  def upload
    self.uri = File.join(WAREHOUSE_CONFIG['baseurl'], "#{uuid}")
    response = Typhoeus::Request.put(self.uri, :body => xml.to_xml, :timeout => 30000)
    if response.code == 200
      update_attribute(:uploaded, true)
    else
      raise "failed to upload template (code #{response.code}): #{response.body}"
    end
  end

  def generate_uuid
    # TODO: generate real uuid here, e.g. with some ruby uuid generator
    self.uuid ||= "#{self.name}-#{Time.now.to_f.to_s}"
  end

  def update_xml
    xml.name = self.name
    xml.description = self.summary
    xml.platform = self.platform
    xml.platform_version = self.platform_version
    xml.architecture = self.architecture
    write_attribute(:xml, xml.to_xml)
  end

  def providers
    # TODO: rewrite cleanly
    ReplicatedImage.all(
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
end
