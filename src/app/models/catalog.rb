# == Schema Information
#
# Table name: catalogs
#
#  id         :integer         not null, primary key
#  pool_id    :integer
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Catalog < ActiveRecord::Base
  include PermissionedObject

  belongs_to :pool
  has_many :catalog_entries, :dependent => :destroy
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  validates_presence_of :pool
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 1024

end
