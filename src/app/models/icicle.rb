# == Schema Information
# Schema version: 20110223132404
#
# Table name: icicles
#
#  id                :integer         not null, primary key
#  uuid              :string(255)
#  xml               :text
#  provider_image_id :integer
#  created_at        :datetime
#  updated_at        :datetime
#

class Icicle < ActiveRecord::Base
  validates_presence_of :uuid
  validates_uniqueness_of :uuid
  belongs_to :provider_image
end
