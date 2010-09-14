#
# Copyright (C) 2009 Red Hat, Inc.
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

class ImageController < ApplicationController
  before_filter :require_user

  def index
  end

  def cancel
    Image.update(params[:id], :status => Image::STATE_CANCELED)
    redirect_to :controller => 'templates', :action => 'new', :params => {'image_descriptor[id]' => params[:template_id], :tab => 'software'}
  end

  def show
    if params[:create_instance]
      redirect_to :controller => 'instance', :action => 'new', 'instance[image_id]' => (params[:ids] || []).first
    end

    require_privilege(Privilege::IMAGE_VIEW)

    @order_dir = params[:order_dir] == 'desc' ? 'desc' : 'asc'
    @order = params[:order] || 'name'
    @images = Image.search_filter(params[:search], Image::SEARCHABLE_COLUMNS).paginate(
      :page => params[:page] || 1,
      :order => @order + ' ' + @order_dir,
      :include => :instances
    )

    if request.xhr? and params[:partial]
      render :partial => 'images'
      return
    end
  end
end
