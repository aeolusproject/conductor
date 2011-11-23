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
      if image.delete!
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
