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

Tim::TargetImage.class_eval do
  STATUS_NEW       = 'NEW'
  STATUS_BUILDING  = 'BUILDING'
  STATUS_FAILED    = 'FAILED'
  STATUS_COMPLETE  = 'COMPLETE'

  belongs_to :provider_type

  validates_presence_of :provider_type

  before_validation :set_provider_type
  before_validation :set_target

  def set_provider_type
    # if provider_type is not set but provider_image is set, get provider
    # type from provider image's provider account
    if provider_type.nil? and provider_images.present? and
      provider_images.first.provider_account

      self.provider_type = provider_images.first.provider_account.
        provider.provider_type
    end
  end

  def self.find_by_images(images)
    Tim::TargetImage.joins(:image_version).
      where(:tim_image_versions => {:base_image_id => [images.map(&:id)]})
  end

  def base_image
    image_version.base_image
  end

  def built?
    status == STATUS_COMPLETE || imported?
  end

  def destroyable?
    status == STATUS_FAILED || built?
  end

  def human_status
    if built?
      I18n.t('tim.base_images.target_images.statuses.complete')
    elsif status == STATUS_FAILED
      I18n.t('tim.base_images.target_images.statuses.failed')
    else
      # TODO: is it OK to consider nil status as building?
      I18n.t('tim.base_images.target_images.statuses.building')
    end
  end

  # imagefactory states are not standardized and it can return both
  # COMPLETE and COMPLETED states
  def status=(state)
    state = STATUS_COMPLETE if state == 'COMPLETED'
    write_attribute(:status, state)
  end

  private

  def set_target
    self.target ||= provider_type.imagefactory_target_name
  end
end
