# == Schema Information
# Schema version: 20110223132404
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
  has_one :icicle, :dependent => :destroy

  validates_presence_of :provider_id
  validates_presence_of :image_id
  validates_uniqueness_of :uuid, :allow_nil => true

  def push
    # TODO: this is just stubbed upload call,
    # when new image_builder_service is done, replace
    # with real request to image_builder_service
  end

  def after_update
    if self.uploaded_changed? and self.uploaded == true
      begin
        invoke_sync
      rescue => e
        logger.error e.message
        logger.error e.backtrace.join("\n  ")
      end
    end
  end
end
