require 'util/image_descriptor_xml'
require 'typhoeus'

class Template < ActiveRecord::Base
  has_many :images,  :dependent => :destroy
  before_validation :update_attrs

  WAREHOUSE_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/image_warehouse.yml")

  validates_presence_of :uuid
  #validates_presence_of :name
  validates_uniqueness_of :uuid

  def update_xml_attributes!(opts = {})
    doc = xml
    doc.name = opts[:name] if opts[:name]
    doc.platform = opts[:platform] if opts[:platform]
    doc.description = opts[:description] if opts[:description]
    doc.services = (opts[:services] || []) if opts[:services] or opts[:set_services]
    doc.packages = (opts[:packages] || []) if opts[:packages] or opts[:set_packages]
    save_xml!
  end

  def save_xml!
    self[:xml] = xml.to_xml
    @xml = nil
    save!
  end

  def xml
    @xml ||= ImageDescriptorXML.new(self[:xml].to_s)
  end

  def upload_template
    self.uri = File.join(WAREHOUSE_CONFIG['baseurl'], "template_#{id}")
    response = Typhoeus::Request.put(self.uri, :body => xml.to_xml, :timeout => 30000)
    if response.code == 200
      save!
    else
      raise "failed to upload template (return code #{response.code}): #{response.body}"
    end
    return true
  end

  def update_attrs
    # TODO: generate real uuid here, e.g. with some ruby uuid generator
    self.uuid ||= "#{xml.name}-#{Time.now.to_f.to_s}"
    self.name = xml.name
    self.summary = xml.description
  end

  def providers
    # TODO: rewrite cleanly
    ReplicatedImage.all(
      :include => [:image, :provider],
      :conditions => {:images => {:template_id => self.id}}
    ).map {|p| p.provider}
  end
end
