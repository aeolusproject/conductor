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
    DeployableXML.new(DeployableXML.import_xml_from_url(url))
  end

end
