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

class TargetImagesController < ApplicationController
  before_filter :require_user

  def create
    wh_image = Aeolus::Image::Warehouse::Image.find(params[:image_id])

    begin
      timage = Aeolus::Image::Factory::Image.new(
        :id => params[:image_id],
        :template => wh_image.template_xml.to_s,
        :build_id => params[:build_id],
        :targets => params[:target]
      )
      timage.save!
    rescue
      logger.error $!.message
      logger.error $!.backtrace.join("\n  ")
      flash[:warning] = $!.message
    end
    redirect_to image_path(params[:image_id], :build => params[:build_id])
  end

  def destroy
    if image = Aeolus::Image::Warehouse::TargetImage.find(params[:id])
      i = image.build.image
      if i.imported?
        if i.delete!
          flash[:notice] = t('images.flash.notice.deleted')
          redirect_to images_path
          return
        else
          flash[:warning] = t('images.flash.warning.delete_failed')
        end
      elsif image.delete!
        flash[:notice] = t('target_images.flash.notice.deleted')
      else
        flash[:warning] = t('target_images.flash.warning.delete_failed')
      end
    else
      flash[:warning] = t('target_images.flash.warning.not_found')
    end
    build_id = image.build.id rescue nil
    redirect_to image_path(params[:image_id], :build => build_id)
  end
end
