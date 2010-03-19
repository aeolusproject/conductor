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

require 'util/taskomatic'

class PortalPoolController < ApplicationController
  before_filter :require_user

  def index
    render :action => 'new'
  end

  def show
    #FIXME: clean this up, many error cases here
    @pool = PortalPool.find(params[:id])
    require_privilege(Privilege::INSTANCE_VIEW,@pool)
    # pass nil into Taskomatic as we're not working off a task here
    Taskomatic.new(nil,logger).pool_refresh(@pool)
    @pool.reload
    @instances = @pool.instances
  end

  def hardware_profiles
    @pool = PortalPool.find(params[:id])
    @hardware_profiles = @pool.hardware_profiles
    require_privilege(Privilege::POOL_VIEW, @pool)
  end

  def accounts
    @pool = PortalPool.find(params[:id])
    require_privilege(Privilege::ACCOUNT_VIEW,@pool)
  end

  def realms
    @pool = PortalPool.find(params[:id])
    @realm_names = @pool.realms
    require_privilege(Privilege::POOL_VIEW,@pool)
  end

  def new
    require_privilege(Privilege::POOL_MODIFY)
    @portal_pool = PortalPool.new
    @account = CloudAccount.new
  end

  def create
    require_privilege(Privilege::POOL_MODIFY)

    #FIXME: owner is set to current user for self-service account creation,
    # but in the more general case we need a way for the admin to pick
    # a user
    params[:portal_pool][:owner_id] = @current_user.id

    #FIXME: This should probably be in a transaction
    @portal_pool = PortalPool.new(params[:portal_pool])
    perm = Permission.new(:user => @portal_pool.owner,
                          :role => Role.find_by_name("Instance Creator and User"),
                          :permission_object => @portal_pool)
    perm.save!
    # FIXME: do we need any more handling around save failures? What if perm
    #        creation fails?
    flash[:notice] = "Pool added."
    redirect_to :action => 'show', :id => @portal_pool.id
  end

  def delete
  end


  def images
    @pool = PortalPool.find(params[:portal_pool])
    require_privilege(Privilege::POOL_VIEW, @pool)
  end

  def accounts_for_pool
    @pool =  PortalPool.find(params[:pool_id])
    require_privilege(Privilege::ACCOUNT_ADD,@pool)
    @cloud_accounts = []
    all_accounts = CloudAccount.all
    all_accounts.each {|account|
      if authorized?(Privilege::ACCOUNT_VIEW,account) && authorized?(Privilege::ACCOUNT_ADD,account)
        @cloud_accounts << account unless @pool.cloud_accounts.map{|x| x.id}.include?(account.id)
      end
    }
  end

  def add_account
    @portal_pool = PortalPool.find(params[:portal_pool])
    @cloud_account = CloudAccount.find(params[:cloud_account])
    @portal_pool.cloud_accounts << @cloud_account unless @portal_pool.cloud_accounts.map{|x| x.id}.include?(@cloud_account.id)
    @portal_pool.save!
    @portal_pool.populate_realms_and_images([@cloud_account])
    redirect_to :action => 'show', :id => @portal_pool.id
  end


end
