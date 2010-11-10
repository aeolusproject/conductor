require 'util/image_descriptor_xml'
require 'typhoeus'

class Template < ActiveRecord::Base
  has_many :images, :dependent => :destroy
  has_many :instances
  before_validation :update_attrs
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

  def update_xml_attributes(opts = {})
    xml.name = opts[:name] if opts[:name]
    xml.description = opts[:summary] if opts[:summary]
    if plat = opts[:platform]
      xml.platform = plat
      xml.platform_version = platforms[plat]['version'].to_s
      xml.architecture = platforms[plat]['architecture']
    end
    self[:xml] = xml.to_xml
    @xml = nil
    update_attrs
  end

  def xml
    @xml ||= ImageDescriptorXML.new(self[:xml].to_s)
  end

  def upload_template
    self.uri = File.join(WAREHOUSE_CONFIG['baseurl'], "#{uuid}")
    response = Typhoeus::Request.put(self.uri, :body => xml.to_xml, :timeout => 30000)
    if response.code == 200
      update_attribute(:uploaded, true)
    else
      raise "failed to upload template (code #{response.code}): #{response.body}"
    end
  end

  def update_attrs
    # TODO: generate real uuid here, e.g. with some ruby uuid generator
    self.uuid ||= "#{xml.name}-#{Time.now.to_f.to_s}"
    self.name = xml.name
    self.summary = xml.description
    self.platform = xml.platform
    self.platform_version = xml.platform_version
    self.architecture = xml.architecture
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
end
