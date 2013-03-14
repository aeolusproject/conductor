#
#   Copyright 2013 Red Hat, Inc.
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

module DeployableMatching

  class ImageFetcher

    def self.base_image(assembly)
      if assembly.image_id
        fetch_base_image_by_id(assembly.image_id)
      elsif assembly.image_build
        fetch_base_image_by_build(assembly.image_build)
      end
    end

    def self.image_arch(assembly)
      base_image = base_image(assembly)

      # try to get architecture of the image associated with this instance
      # for imported images template is empty -> architecture is not set,
      # in this case we omit this check
      return base_image.template.os.arch
    rescue => ex
      Rails.logger.warn "failed to get image architecture for image, skipping architecture check: #{ex.message}"
      Rails.logger.warn ex.backtrace.join("\n")
      nil
    end

    def self.provider_image(assembly, provider_account)
      if assembly.image_build
        base_image = fetch_base_image_by_build(assembly.image_build)
        if base_image
          return Tim::ProviderImage.find_by_provider_account_and_image_version(
                   provider_account, base_image).complete.first
        end
      elsif assembly.image
        base_image = fetch_base_image_by_id(assembly.image_id)
        if base_image
          return Tim::ProviderImage.find_by_provider_account_and_image(
                   provider_account, base_image).complete.order('created_at DESC').first
        end
      end

      nil
    end

    private

    def self.fetch_base_image_by_id(image_id)
      return nil if image_id.nil?
      Tim::BaseImage.find_by_uuid(image_id)
    end

    def self.fetch_base_image_by_build(image_build)
      return nil if image_build.nil?
      Tim::ImageVersion.find_by_uuid(image_build)
    end

  end

end
