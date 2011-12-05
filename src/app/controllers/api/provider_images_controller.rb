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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Api
  class ProviderImagesController < ApplicationController
    before_filter :require_user_api

    respond_to :xml
    layout :false

    def index
      if id = params[:target_image_id]
        if target_image = Aeolus::Image::Warehouse::TargetImage.find(params[:target_image_id])
          @images = target_image.provider_images
        else
          raise(Aeolus::Conductor::API::TargetImageNotFound.new(400, t("api.error_messages.target_image_not_found", :targetimage => id)))
        end
      else
        @images = Aeolus::Image::Warehouse::ProviderImage.all
      end
      respond_with(@images)
    end

    def show
      id = params[:id]
      @image = Aeolus::Image::Warehouse::ProviderImage.find(id)
      if @image
        respond_with(@image)
      else
        status = Aeolus::Image::Factory::ProviderImage.status(id)
        if !status.nil?
          @image = Aeolus::Image::Factory::ProviderImage.new(:id => id,
                                                             :href => api_provider_image_url(id),
                                                             :status => status)
          respond_with(@image)
        else
          raise(Aeolus::Conductor::API::ProviderImageStatusNotFound.new(404, t("api.error_messages.provider_image_status_not_found", :providerimage => id)))
        end
      end
    end

    def create
      doc = Nokogiri::XML CGI.unescapeHTML(request.body.read)
      begin
        target_images = list_target_images(doc)
      rescue ActiveResource::BadRequest => e
        raise(Aeolus::Conductor::API::InsufficientParametersSupplied.new(400, t("api.error_messages.in_grabbing_target_images", :error => e.message)))
        return
      end

      @provider_images = []
      @errors = []
      doc.xpath("/provider_image/provider_account").text.split(",").each do |account_name|
        account = ProviderAccount.find_by_label(account_name)
        if !account
          raise(Aeolus::Conductor::API::ProviderAccountNotFound.new(404, t("api.error_messages.provider_account_not_found", :name => account_name)))
        end

        target_image = find_target_image_for_account(target_images, account)
        if !target_image
          raise(Aeolus::Conductor::API::TargetImageNotFound.new(404, t("api.error_messages.target_image_not_found_for_account", :account => account_name)))
        end

        begin
          @provider_images << send_push_request(target_image, account)
        rescue ActiveResource::BadRequest
          raise(Aeolus::Conductor::API::ParameterDataIncorrect.new(400, t("api.error_messages.invalid_parameters_for_account_and_target_image", :account => account_name, :targetimage => target_image.id)))
        rescue => e
          raise(Aeolus::Conductor::API::PushError.new(500, t("api.error_messages.push_error", :targetimage => target_image.id, :account => account_name, :error => e.message)))
        end
      end
    end

    def destroy
      begin
        if @image = Aeolus::Image::Warehouse::ProviderImage.find(params[:id])
          if @image.delete!
            respond_with(@image)
          end
        else
          raise(Aeolus::Conductor::API::ProviderImageNotFound.new(404, t("api.error_messages.provider_image_not_found", :providerimage => params[:id])))
        end
      rescue Aeolus::Conductor::API::ProviderImageNotFound => e
        raise(e)
      rescue => e
        raise(Aeolus::Conductor::API::ProviderImageDeleteFailure.new(500, e.message))
      end
    end

    def list_target_images(doc)
      if doc.xpath("/provider_image/provider_account").empty?
        raise(Aeolus::Conductor::API::InsufficientParametersSupplied.new(400, t("api.error_messages.no_provider_account_given")))
      else
        target_images = []
        if !doc.xpath("/provider_image/image_id").empty?
          image_id = doc.xpath("/provider_image/image_id").text
          image = Aeolus::Image::Warehouse::Image.find(image_id)
          if !image
            raise(Aeolus::Conductor::API::ImageNotFound.new(404, t("api.error_messages.image_not_found", :image => image_id)))
          end
          image.image_builds.each do |build|
            target_images += build.target_images
          end
          target_images
        elsif !doc.xpath("/provider_image/build_id").empty?
          build_id = doc.xpath("/provider_image/build_id").text
          if build = Aeolus::Image::Warehouse::ImageBuild.find(build_id)
            target_images = build.target_images
          else
            raise(Aeolus::Conductor::API::BuildNotFound.new(404, t("api.error_messages.build_not_found", :build => build_id)))
          end
        elsif !doc.xpath("/provider_image/target_image_id").empty?
          target_image_id = doc.xpath("/provider_image/target_image_id").text
          target_image = Aeolus::Image::Warehouse::TargetImage.find(target_image_id)
          if !target_image
            raise(Aeolus::Conductor::API::TargetImageNotFound.new(404, t("api.error_messages.target_image_not_found", :targetimage => target_image_id)))
          end
          target_images << target_image
        else
          raise(Aeolus::Conductor::API::InsufficientParametersSupplied.new(400, t("api.error_messages.no_image_build_or_target_image")))
        end
        if target_images.empty?
          raise(Aeolus::Conductor::API::InsufficientParametersSupplied.new(400, t("api.error_messages.no_matching_target_image")))
        else
          target_images
        end
      end
    end

    def send_push_request(target_image, account)
      provider_image = Aeolus::Image::Factory::ProviderImage.new({:provider => account.provider.name,
                                                                  :credentials => account.to_xml(:with_credentials => true),
                                                                  :image_id => target_image.build.image.id,
                                                                  :build_id => target_image.build.id,
                                                                  :target_image_id => target_image.id })
      provider_image.save!
      provider_image
    end

    def find_target_image_for_account(target_images, account)
      target_images.each do |target_image|
        if target_image.target == account.provider.provider_type.deltacloud_driver
          return target_image
        end
      end
      nil
    end

  end
end
