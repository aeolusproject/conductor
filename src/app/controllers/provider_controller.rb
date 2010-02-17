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

class ProviderController < ApplicationController
  before_filter :require_user

  def index
    render :action => 'new'
  end

  def show
    @provider = Provider.find(:first, :conditions => {:id => params[:id]})
  end

  def new
    @provider = Provider.new(params[:provider])
    if request.post? && @provider.save && @provider.populate_hardware_profiles
      flash[:notice] = "Provider added."
      redirect_to :action => "show", :id => @provider
    end
  end

  def destroy
    if request.post?
      p =Provider.find(params[:provider][:id])
      p.destroy
    end
    redirect_to :action => "index"
  end

end
