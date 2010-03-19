#
# Copyright (C) 2010 Red Hat, Inc.
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

class CloudAccountsController < ApplicationController
  before_filter :require_user

  def new
    @cloud_account = CloudAccount.new
    @providers = []
    all_providers = Provider.all
    all_providers.each {|provider|
      @providers << provider if authorized?(Privilege::PROVIDER_VIEW,provider)
    }
  end

  def new_from_pool
    @pool = PortalPool.find(params[:pool_id])
    require_privilege(Privilege::ACCOUNT_ADD,@pool)
    @cloud_account = CloudAccount.new
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_VIEW)
  end


  def create
    @cloud_account = CloudAccount.new(params[:cloud_account])
    @provider = Provider.find(params[:provider][:id])
    require_privilege(Privilege::ACCOUNT_MODIFY,@provider)
    @cloud_account.provider = @provider
    @cloud_account.save!
  end

  def create_from_pool
    @pool = PortalPool.find(params[:pool][:id])
    require_privilege(Privilege::ACCOUNT_ADD,@pool)
    PortalPool.transaction do
      @cloud_account = CloudAccount.new(params[:cloud_account])
      @provider = Provider.find(params[:provider][:id])
      @cloud_account.provider = @provider
      @cloud_account.save!
      @pool.cloud_accounts << @cloud_account unless @pool.cloud_accounts.map{|x| x.id}.include?(@cloud_account.id)
      @pool.save!
      @pool.populate_realms_and_images([@cloud_account])
      perm = Permission.new(:user => @current_user,
                            :role => Role.find_by_name("Account Administrator"),
                            :permission_object => @cloud_account)
      perm.save!
    end
    redirect_to :controller => "portal_pool", :action => 'show', :id => @pool.id
  end


end
