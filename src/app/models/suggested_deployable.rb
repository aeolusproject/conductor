# == Schema Information
# Schema version: 20110607104800
#
# Table name: suggested_deployables
#
#  id          :integer         not null, primary key
#  name        :string(1024)    not null
#  description :text            not null
#  url         :string(255)
#

class SuggestedDeployable < ActiveRecord::Base
  include PermissionedObject

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 1024
  validates_presence_of :url

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  after_create "assign_owner_roles(owner)"
end
