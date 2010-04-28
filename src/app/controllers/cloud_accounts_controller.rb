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

  def create
    @cloud_account = CloudAccount.new(params[:cloud_account])
    @provider = Provider.find(params[:provider][:id])
    require_privilege(Privilege::ACCOUNT_MODIFY,@provider)
    @cloud_account.provider = @provider
    @cloud_account.save!
  end

  def edit
    @cloud_account = CloudAccount.find(params[:id])
    @provider = @cloud_account.provider
    require_privilege(Privilege::ACCOUNT_MODIFY,@provider)
  end

  def update
    @cloud_account = CloudAccount.find(params[:cloud_account][:id])
    require_privilege(Privilege::ACCOUNT_MODIFY,@cloud_account.provider)
    if @cloud_account.update_attributes(params[:cloud_account])
      flash[:notice] = "Cloud Account updated!"
      redirect_to :controller => 'provider', :action => 'accounts', :id => @cloud_account.provider.id
    else
      render :action => :edit
    end
  end

  def destroy
    acct = CloudAccount.find(params[:id])
    provider = acct.provider
    require_privilege(Privilege::ACCOUNT_MODIFY,provider)
    if acct.destroyable?
      CloudAccount.destroy(params[:id])
      flash[:notice] = "Cloud Account destroyed"
    else
      flash[:notice] = "Cloud Account could not be destroyed"
    end
    redirect_to :controller => 'provider', :action => 'accounts', :id => provider.id
  end
end
