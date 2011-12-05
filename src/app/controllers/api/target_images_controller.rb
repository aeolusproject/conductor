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
  class TargetImagesController < ApplicationController
    before_filter :require_user_api

    respond_to :xml
    layout :false

    def index
      if id = params[:build_id]
        if build = Aeolus::Image::Warehouse::ImageBuild.find(params[:build_id])
          @images = build.target_images
        else
          raise(Aeolus::Conductor::API::BuildNotFound.new(400, t("api.error_messages.build_not_found", :build => id)))
        end
      else
        @images = Aeolus::Image::Warehouse::TargetImage.all
      end
      respond_with(@images)
    end

    def show
      id = params[:id]
      @image = Aeolus::Image::Warehouse::TargetImage.find(id)
      if @image
        respond_with(@image)
      else
        status = Aeolus::Image::Factory::TargetImage.status(id)
        if !status.nil?
          @image = Aeolus::Image::Factory::TargetImage.new(:id => id,
                                                           :href => api_target_image_url(id),
                                                           :status => status)
          respond_with(@image)
        else
          raise(Aeolus::Conductor::API::TargetImageStatusNotFound.new(404, t("api.error_messages.target_image_status_not_found", :targetimage => id)))
        end
      end
    end

    def destroy
      begin
        if @image = Aeolus::Image::Warehouse::TargetImage.find(params[:id])
          @provider_images = @image.provider_images
          if @image.delete!
            respond_with(@image, @provider_images)
          end
        else
          raise(Aeolus::Conductor::API::TargetImageNotFound.new(404, t("api.error_messages.target_image_not_found", :targetimage => params[:id])))
        end
      rescue => e
        raise(Aeolus::Conductor::API::TargetImageDeleteFailure.new(500, e.message))
      end
    end
  end
end
