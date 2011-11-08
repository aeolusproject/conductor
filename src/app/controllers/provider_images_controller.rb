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

class ProviderImagesController < ApplicationController
  before_filter :require_user

  def index
  end

  def show
  end

  def edit
  end

  def update
  end

  def create
    provider_account = ProviderAccount.find(params[:account_id])
    @provider_image = Aeolus::Image::Factory::ProviderImage.new(
      :provider => provider_account.provider.name,
      :credentials => provider_account.to_xml(:with_credentials => true),
      :image_id => params[:image_id],
      :build_id => params[:build_id],
      :target_image_id => params[:target_image_is]
    )
    if @provider_image.save
      flash[:notice] = t('provider_images.flash.notice.upload_start')
    else
      flash[:warning] = t('provider_images.flash.warning.upload_failed')
    end
    redirect_to image_path(params[:image_id])
  end

  def destroy
    if image = Aeolus::Image::Warehouse::ProviderImage.find(params[:id])
      if image.delete!
        flash[:notice] = t('provider_images.flash.notice.deleted')
      else
        flash[:warning] = t('provider_images.flash.warning.delete_failed')
      end
    else
      flash[:warning] = t('provider_images.flash.warning.not_found')
    end
    redirect_to image_path(params[:image_id])
  end
end
