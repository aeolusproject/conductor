#
#   Copyright 2011 Red Hat, Inc.
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

class Image
  # Given a ProviderAccount and an AMI/image ID on a provider, plus an optional XML string, use aeolus-image
  # to import the image. Returns an Aeolus::Image::Factory::Image or allows exceptions to bubble up
  def self.import(provider_account, image_id, environment, xml=nil)
    raise Aeolus::Conductor::Base::BlankImageId unless image_id.present?
    # Verify that the image exists prior to import
    conn = provider_account.connect
    img = conn.image(image_id) rescue nil
    raise Aeolus::Conductor::Base::ImageNotFound unless img.present?
    # We have the image name in the cloud provider, so we might as well use it
    xml ||= "<image><name>#{img.name}</name></image>" if img.name.present?
    provider = provider_account.provider
    account_id = provider_account.credentials_hash['username']
    image = Aeolus::Image.import(provider.name, provider.provider_type.deltacloud_driver, image_id, account_id, xml)
    image.set_attr("environment", environment.name)
    image
  end
end
