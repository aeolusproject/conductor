# == Schema Information
# Schema version: 20110302120000
#
# Table name: provider_images
#
#  id                 :integer         not null, primary key
#  image_id           :integer         not null
#  provider_id        :integer         not null
#  provider_image_key :string(255)
#  uuid               :string(255)
#  status             :string(255)
#

class ProviderImage < ActiveRecord::Base
  include ImageWarehouseObject

  belongs_to :provider
  belongs_to :image
  has_one :icicle, :dependent => :destroy

  validates_presence_of :provider_id
  validates_presence_of :image_id
  validates_uniqueness_of :uuid, :allow_nil => true
  validates_uniqueness_of :image_id, :scope => :provider_id

  STATE_QUEUED = 'queued'
  STATE_COMPLETED = 'completed'
  STATE_CANCELED = 'canceled'
  STATE_FAILED = 'failed'

  ACTIVE_STATES = [ STATE_QUEUED ]
  INACTIVE_STATES = [STATE_COMPLETED, STATE_FAILED, STATE_CANCELED]

  def after_update
    if self.status_changed? and self.status == STATE_COMPLETED
      begin
        invoke_sync
      rescue => e
        logger.error e.message
        logger.error e.backtrace.join("\n  ")
      end
    end
  end
end
