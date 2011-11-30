#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Api
  class TargetImagesController < ApplicationController
    before_filter :require_user_api

    respond_to :xml
    layout :false

    def index
      if params[:build_id]
        @images = Aeolus::Image::Warehouse::ImageBuild.find(params[:build_id]).target_images
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
