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
  before_filter :load_providers, :only => [:index, :show, :accounts, :list]

  def section_id
    'administration'
  end

  def index
  end

  def show
    @provider = Provider.find(:first, :conditions => {:id => params[:id]})
    require_privilege(Privilege::PROVIDER_VIEW, @provider)
  end

  def edit
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_MODIFY)
    @provider = Provider.find(:first, :conditions => {:id => params[:id]})
    require_privilege(Privilege::PROVIDER_MODIFY, @provider)
    render :show
  end

  def new
    require_privilege(Privilege::PROVIDER_MODIFY)
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_MODIFY)
    @provider = Provider.new(params[:provider])
    kick_condor
    render :show
  end

  def create
    require_privilege(Privilege::PROVIDER_MODIFY)
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_MODIFY)
    @provider = Provider.new(params[:provider])
    @provider.set_cloud_type!
    if @provider.save && @provider.populate_hardware_profiles
        flash[:notice] = "Provider added."
        redirect_to :action => "show", :id => @provider
    else
      flash[:notice] = "Cannot add the provider."
      render :action => "new"
    end
    kick_condor
  end

  def update
    require_privilege(Privilege::PROVIDER_MODIFY)
    @provider = Provider.find(:first, :conditions => {:id => params[:provider][:id]})
    @provider.name = params[:provider][:name]

    if @provider.save
        flash[:notice] = "Provider updated."
        redirect_to :action => "show", :id => @provider
    else
      render :action => "edit"
    end
    kick_condor
  end

  def destroy
    if request.post?
      @provider = Provider.find(params[:provider][:id])
      require_privilege(Privilege::PROVIDER_MODIFY, p)
      if @provider.destroy and @provider.destroyed?
        redirect_to :action => "index"
      else
        flash[:error] = {
          :summary => "Failed to delete Provider",
          :failures => @provider.errors.full_messages,
        }
        render :action => 'show'
      end
    end
  end

  def hardware_profiles
    @provider = Provider.find(params[:id])
    @hardware_profiles = @provider.hardware_profiles
    require_privilege(Privilege::PROVIDER_VIEW, @provider)
  end

  def accounts
    @provider = Provider.find(:first, :conditions => {:id => params[:id]})
    require_privilege(Privilege::ACCOUNT_VIEW, @provider)
  end

  def realms
    @provider = Provider.find(params[:id])
    @realm_names = @provider.realms.collect { |r| r.name }
    require_privilege(Privilege::PROVIDER_VIEW, @provider)
  end

  def settings
    @provider = Provider.find(params[:id])
  end

  def list
  end

  protected
  def load_providers
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_VIEW)
  end
end
