#
#   Copyright 2012 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

Tim::ProviderImage.class_eval do
  # const in a class_eval block is defined in scope in which the block
  # is called, also behavior is different in various versions of ruby
  # -> full const path is used
  Tim::ProviderImage::STATUS_NEW       = 'NEW'
  Tim::ProviderImage::STATUS_PUSHING   = 'PUSHING'
  Tim::ProviderImage::STATUS_FAILED    = 'FAILED'
  Tim::ProviderImage::STATUS_COMPLETE  = 'COMPLETE'
  Tim::ProviderImage::STATUS_IMPORTED  = 'IMPORTED'

  belongs_to :provider_account

  validates_presence_of :provider_account
  validate :valid_external_image_id?, :if => :should_validate_external_image?

  before_create :set_credentials
  before_create :set_provider

  scope :complete, :conditions => { :status => [
    Tim::ProviderImage::STATUS_COMPLETE, Tim::ProviderImage::STATUS_IMPORTED] }

  def self.find_by_images(images)
    Tim::ProviderImage.joins(:target_image => :image_version).
      where(:tim_image_versions => {:base_image_id => [images.map(&:id)]})
  end

  def self.find_by_provider_account_and_image_version(account, version)
    joins(:target_image => :image_version).
      where(:provider_account_id => account.id,
            'tim_image_versions.id' => version.id)
  end

  def self.find_by_provider_account_and_image(account, image)
    joins(:target_image => :image_version).
      where(:tim_image_versions => {:base_image_id => image.id},
            :provider_account_id => account.id)
  end

  def base_image
    target_image.base_image
  end

  def should_validate_external_image?
    imported? && external_image_id.present?
  end

  def valid_external_image_id?
    account = ProviderAccount.find(provider_account_id)
    conn = provider_account.connect

    dc_image = conn.image(external_image_id) rescue nil
    if dc_image.blank?
      errors.add(:external_image_id, I18n.t('tim.base_images.import.not_on_provider'))
      return false
    end

    true
  end

  # This is a misnomer -- a TargetImage is built, and a ProviderImage is pushed.
  def built?
    target_image.built?
  end

  def pushing?
    [Tim::ProviderImage::STATUS_NEW, Tim::ProviderImage::STATUS_PUSHING].include?(status)
  end

  def pushed?
    self.status == Tim::ProviderImage::STATUS_COMPLETE || imported?
  end

  def destroyable?
    self.status == Tim::ProviderImage::STATUS_FAILED || pushed?
  end

  def human_status
    if built?
      I18n.t('tim.base_images.provider_image.statuses.complete')
    elsif status == Tim::ProviderImage::STATUS_FAILED
      I18n.t('tim.base_images.provider_image.statuses.failed')
    else
      # TODO: is it OK to consider nil status as pushing?
      I18n.t('tim.base_images.provider_image.statuses.pushing')
    end
  end

  # imagefactory states are not standardized and it can return both
  # COMPLETE and COMPLETED states
  def status=(state)
    state = Tim::ProviderImage::STATUS_COMPLETE if state == 'COMPLETED'
    write_attribute(:status, state)
  end

  private

  def set_credentials
    @credentials = provider_account.to_xml(:with_credentials => true)
  end

  # this is useless in conductor, but imagefactory requires provider
  # attr to be set
  def set_provider
    self.provider = provider_account.provider.name
  end
end
