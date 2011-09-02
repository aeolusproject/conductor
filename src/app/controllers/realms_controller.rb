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

class RealmsController < ApplicationController
  before_filter :require_user
  before_filter :load_realms, :only =>[:index, :show]

  def index
    clear_breadcrumbs
    save_breadcrumb(realms_path)
  end

  def new
    require_privilege(Privilege::CREATE, Realm)
    @realm = FrontendRealm.new
    load_backend_realms
  end

  def edit
    require_privilege(Privilege::MODIFY, Realm)
    @realm = FrontendRealm.find(params[:id])
    load_backend_realms
  end

  def update
    require_privilege(Privilege::MODIFY, Realm)
    @realm = FrontendRealm.find(params[:id])

    if params[:commit] == "Reset"
      redirect_to edit_realm_url(@realm) and return
    end

    if @realm.update_attributes(params[:frontend_realm])
      flash[:notice] = 'Realm updated successfully!'
      redirect_to realms_url and return
    end

    load_backend_realms
    render :action => 'edit'
  end

  def create
    require_privilege(Privilege::CREATE, Realm)
    @realm = FrontendRealm.new(params[:frontend_realm])
    if @realm.save
      flash[:notice] = "Realm was added."
      redirect_to realm_path(@realm)
    else
      load_backend_realms
      render :new
    end
  end

  def destroy
    require_privilege(Privilege::MODIFY, Realm)
    if FrontendRealm.destroy(params[:id])
      flash[:notice] = "Realm was deleted!"
    else
      flash[:error] = "Realm was not deleted!"
    end
    redirect_to realms_path
  end

  def multi_destroy
    deleted = []
    not_deleted = []
    if params[:realm_selected].blank?
      flash[:error] = 'You must select at least one realm to delete.'
    else
      FrontendRealm.find(params[:realm_selected]).each do |realm|
        require_privilege(Privilege::MODIFY, Realm)
        if realm.destroy
          deleted << realm.name
        else
          not_deleted << realm.name
        end
      end
    end

    unless deleted.empty?
      flash[:notice] = "These Realms were deleted: #{deleted.join(', ')}"
    end
    unless not_deleted.empty?
      flash[:error] = "Could not deleted these Realms: #{not_deleted.join(', ')}"
    end
    redirect_to realms_path
  end

  def show
    @realm = FrontendRealm.find(params[:id])

    @tab_captions = ['Properties', 'Mapping']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]

    @backend_realm_targets = @realm.realm_backend_targets.select { |x| x.realm_or_provider_type == 'Realm' }
    @backend_provider_targets = @realm.realm_backend_targets.select { |x| x.realm_or_provider_type == 'Provider' }

    save_breadcrumb(realm_path(@realm), @realm.name)

    respond_to do |format|
      format.html { render :action => 'show' }
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab
      end
    end
  end

  protected

  def load_backend_realms
    #TODO: list only realms user has permission on
    @backend_realms = Realm.all
    @providers = Provider.list_for_user(current_user, Privilege::VIEW)
  end

  def load_realms
    @header = [
      {:name => '', :sortable => false},
      {:name => t("realms.index.realm_name"), :sort_attr => :name},
    ]
    @realms = FrontendRealm.all
  end
end
