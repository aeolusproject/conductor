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

  # Given a Provider and an image ID, import the image
  #  xml is an optional XML file describing the image (if omitted, we generate the XML)
  #  account is an optional ProviderAccount that is attached after the fact
  # Returns the Aeolus::Image::Warehouse::Image object, or raises any exceptions encountered
  def self.import(provider, image_id, xml=nil, account=nil)
    xml ||= "<image><name>#{image_id}</name></image>"
    image = Aeolus::Image::Factory::Image.new(
      :target_name => provider.provider_type.deltacloud_driver,
      :provider_name => provider.name,
      :target_identifier => image_id,
      :image_descriptor => xml
    )
    image.save!
    iwhd_image = Aeolus::Image::Warehouse::Image.find(image.id)
    # If we have an account, set it:
    if account
      pimg = iwhd_image.provider_images.first
      pimg.set_attr('provider_account_identifier', account.credentials_hash['username'])
    end
    iwhd_image
  end

end
