# == Schema Information
# Schema version: 20110221125633
#
# Table name: provider_images
#
#  id                 :integer         not null, primary key
#  image_id           :integer         not null
#  provider_id        :integer         not null
#  provider_image_key :string(255)
#  uploaded           :boolean
#  registered         :boolean
#  uuid               :string(255)
#

class ProviderImage < ActiveRecord::Base
  belongs_to :provider
  belongs_to :image

  validates_presence_of :provider_id
  validates_presence_of :image_id
  validates_uniqueness_of :uuid, :allow_nil => true
end
