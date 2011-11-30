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
  class BuildsController < ApplicationController
    before_filter :require_user_api

    respond_to :xml
    layout :false

    def index
      if params[:image_id]
        @builds = Aeolus::Image::Warehouse::ImageBuild.find_all_by_image_uuid(params[:image_id])
      else
        @builds = Aeolus::Image::Warehouse::ImageBuild.all
      end
      respond_with(@builds)
    end

    def show
      id = params[:id]
      @build = Aeolus::Image::Warehouse::ImageBuild.find(id)
      if @build
        respond_with(@build)
      else
        raise(Aeolus::Conductor::API::BuildNotFound.new(404, t("api.error_messages.build_not_found", :build => id)))
      end
    end

    def destroy
      begin
        if @build = Aeolus::Image::Warehouse::ImageBuild.find(params[:id])
          @provider_images = @build.provider_images
          if @build.delete!
            respond_with(@build, @provider_images)
          end
        else
          raise(Aeolus::Conductor::API::BuildNotFound.new(404, t("api.error_messages.build_not_found", :build => params[:id])))
        end
      rescue Aeolus::Conductor::API::BuildNotFound => e
        raise(e)
      rescue => e
        raise(Aeolus::Conductor::API::BuildDeleteFailure.new(500, e.message))
      end
    end
  end
end
