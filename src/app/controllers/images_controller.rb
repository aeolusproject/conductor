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

class ImagesController < ApplicationController
  before_filter :require_user

  def index
    set_admin_environments_tabs 'images'
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t('images.index.name'), :sort_attr => :name },
      { :name => t('images.index.os'), :sort_attr => :name },
      { :name => t('images.index.os_version'), :sort_attr => :name },
      { :name => t('images.index.architecture'), :sort_attr => :name },
    ]
    @images = Aeolus::Image::Warehouse::Image.all
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
    end
  end

  def show
    @image = Aeolus::Image::Warehouse::Image.find(params[:id])
    @builds = @image.image_builds
    @build = if params[:build].present?
               @builds.find {|b| b.id == params[:build]}
             elsif @image.latest_build
               @builds.find {|b| b.id == @image.latest_build}
             else
               @builds.first
             end
    @provider_types = ProviderType.all
  end

  def edit
  end

  def update
  end

  def create
  end

  def destroy
    if image = Aeolus::Image::Warehouse::Image.find(params[:id])
      if image.delete!
        flash[:notice] = t('images.flash.notice.deleted')
      else
        flash[:warning] = t('images.flash.warning.delete_failed')
      end
    else
      flash[:warning] = t('images.flash.warning.not_found')
    end
    redirect_to images_path
  end

  def multi_destroy
    selected_images = params[:images_selected].to_a
    selected_images.each do |uuid|
      image = Aeolus::Image::Warehouse::Image.find(uuid)
      image.delete!
    end
    redirect_to images_path, :notice => t("images.flash.notice.multiple_deleted", :count => selected_images.count)
  end
end
