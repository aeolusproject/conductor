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
  class BuildsController < ApplicationController
    before_filter :require_user_api

    respond_to :xml
    layout :false

    def index
      if params[:image_id]
        @builds = Aeolus::Image::Warehouse::Image.find(params[:image_id]).image_builds
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
