class ProviderImage < ActiveRecord::Base
  belongs_to :provider
  belongs_to :image

  validates_presence_of :provider_id
  validates_presence_of :image_id
end
