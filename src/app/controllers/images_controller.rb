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
    build_id = params[:build].blank? ? @image.latest_build : params[:build]
    @build = @builds.find {|b| b.id == build_id}
  end

  def edit
  end

  def update
  end

  def create
  end

  def destroy
  end
end
