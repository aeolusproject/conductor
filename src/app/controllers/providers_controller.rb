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

class ProvidersController < ApplicationController
  before_filter :require_user
  before_filter :load_providers, :only => [:index, :show, :edit, :new, :accounts, :list]

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
  end

  def new
    require_privilege(Privilege::PROVIDER_MODIFY)
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_MODIFY)
    @provider = Provider.new(params[:provider])
    kick_condor
  end

  def create
    require_privilege(Privilege::PROVIDER_MODIFY)
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_MODIFY)
    @provider = Provider.new(params[:provider])

    if params[:test_connection]
      test_connection(@provider)
      render :action => "new"
    else
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
  end

  def update
    require_privilege(Privilege::PROVIDER_MODIFY)
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_MODIFY)
    @provider = Provider.find(:first, :conditions => {:id => params[:id]})
    previous_cloud_type = @provider.cloud_type

    @provider.update_attributes(params[:provider])
    if params[:test_connection]
      test_connection(@provider)
      render :action => "edit"
    else
      @provider.set_cloud_type!
      if previous_cloud_type != @provider.cloud_type
        @provider.errors.add :url, "points to a different provider"
      end

      if @provider.errors.empty? and @provider.save
        flash[:notice] = "Provider updated."
        redirect_to :action => "show", :id => @provider
      else
        flash[:notice] = "Cannot update the provider."
        render :action => "edit"
      end
      kick_condor
    end
  end

  def destroy
    if request.post? || request.delete?
      @provider = Provider.find(params[:id])
      require_privilege(Privilege::PROVIDER_MODIFY, @provider)
      if @provider.destroy and @provider.destroyed?
        redirect_to :action => "index"
        flash[:notice] = "Provider Deleted"
        return
      end

      flash[:error] = {
        :summary => "Failed to delete Provider",
        :failures => @provider.errors.full_messages,
      }
    end
    render :action => 'show'
  end

  def hardware_profiles
    @provider = Provider.find(params[:id])
    @hardware_profiles = @provider.hardware_profiles
    require_privilege(Privilege::PROVIDER_VIEW, @provider)
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

  def test_connection(provider)
    @provider.errors.clear
    if @provider.connect
      flash[:notice] = "Successfuly Connected to Provider"
    else
      flash[:notice] = "Failed to Connect to Provider"
      @provider.errors.add :url
    end
  end

  protected
  def load_providers
    @providers = Provider.list_for_user(@current_user, Privilege::PROVIDER_VIEW)
  end
end
