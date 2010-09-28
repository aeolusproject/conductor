require 'util/image_descriptor_xml'
require 'typhoeus'

class Template < ActiveRecord::Base
  has_many :images,  :dependent => :destroy
  before_validation :update_attrs

  WAREHOUSE_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/image_warehouse.yml")

  validates_presence_of :uuid
  validates_uniqueness_of :uuid
  # uncomment this after reworking view (currently is used wizard,
  # so there can be situation when save is called and name and platform can be
  # unset)
  validates_presence_of :name
  validates_presence_of :platform
  validates_presence_of :platform_version
  validates_presence_of :architecture

  def update_xml_attributes!(opts = {})
    doc = xml
    doc.name = opts[:name] if opts[:name]
    doc.platform = opts[:platform] if opts[:platform]
    doc.description = opts[:summary] if opts[:summary]
    doc.platform_version = opts[:platform_version] if opts[:platform_version]
    doc.architecture = opts[:architecture] if opts[:architecture]
    doc.services = (opts[:services] || []) if opts[:services] or opts[:set_services]
    doc.packages = (opts[:packages] || []) if opts[:packages] or opts[:set_packages]
    save_xml!
  end

  def save_xml!
    self[:xml] = xml.to_xml
    @xml = nil
    update_attrs
    save_without_validation!
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
end
