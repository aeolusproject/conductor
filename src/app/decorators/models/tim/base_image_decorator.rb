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

Tim::BaseImage.class_eval do
  include Alberich::PermissionedObject

  belongs_to :pool_family

  validates_presence_of :pool_family_id

  before_create :generate_uuid

  # TODO: Tim uses nested_attributes heavily, when importing an image
  # whole stack of nested objects is created/validated, but then validation
  # attribute name looks like:
  # image_versions.target_images.provider_images.external_image_id
  # More human readable translations are defined in localization file.
  def self.human_attribute_name(attr, opts = {})
    I18n.t("tim.base_images.import.#{attr}", :default => opts[:default])
  end

  def perm_ancestors
    super + [pool_family]
  end

  def imported?
    !!import
  end

  def last_built_image_version
    # TODO: returns latest image version for which there is at least one target
    # image (we don't care about build status)
    image_versions.joins(:target_images).order('created_at DESC').first
  end

  def last_provider_image(account)
    Tim::ProviderImage.find_by_provider_account_and_image(account, self).
      where(:status => Tim::ProviderImage::STATUS_COMPLETE).
      order('tim_image_versions.created_at DESC').first
  end

  def provider_images
    Tim::ProviderImage.find_by_images([self])
  end

  private

  def generate_uuid
    self[:uuid] = UUIDTools::UUID.timestamp_create.to_s
  end
end
