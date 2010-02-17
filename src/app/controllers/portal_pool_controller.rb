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

class PortalPoolController < ApplicationController
  before_filter :require_user

  def index
    render :action => 'new'
  end

  def show
    #FIXME: clean this up, many error cases here
    @pool = PortalPool.find(params[:id])
    @instances = @pool.instances
  end

  def new
    @portal_pool = PortalPool.new
    @account = CloudAccount.new
    @account.provider_id = params[:provider]
  end

  def create
    @account = CloudAccount.find_or_create(params[:account])
    #FIXME: owner is set to current user for self-service account creation,
    # but in the more general case we need a way for the admin to pick
    # a user
    # FIXME: automatically grant owner access rights to the pool
    params[:portal_pool][:owner_id] = @current_user.id
    #FIXME: This should probably be in a transaction
    if @account.save
      @portal_pool = PortalPool.new(params[:portal_pool])
      @portal_pool.cloud_accounts << @account
      if @portal_pool.save && @portal_pool.populate_realms_and_images([@account])
        flash[:notice] = "Pool added."
        redirect_to :action => 'show', :id => @portal_pool.id
      else
        render :action => 'new'
      end
    else
      render :action => 'new'
    end
  end

  def delete
  end
end
