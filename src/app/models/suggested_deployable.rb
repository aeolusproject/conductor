# == Schema Information
# Schema version: 20110616100915
#
# Table name: suggested_deployables
#
#  id          :integer         not null, primary key
#  name        :string(1024)    not null
#  description :text            not null
#  url         :string(255)
#  owner_id    :integer
#

class SuggestedDeployable < ActiveRecord::Base
  include PermissionedObject

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 1024
  validates_presence_of :url
  validates_format_of :url, :with => URI::regexp

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  after_create "assign_owner_roles(owner)"

  def accessible_and_valid_deployable_xml?(url)
    begin
      deployable_xml = DeployableXML.new(DeployableXML.import_xml_from_url(url))
      deployable_xml.validate!
      true
    rescue
      false
    end
  end

end
