#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

class RealmsController < ApplicationController
  before_filter :require_user
  before_filter :load_realms, :only =>[:index, :show]

  def index
    @title = t('realms.realms')
    clear_breadcrumbs
    save_breadcrumb(realms_path)
    set_admin_content_tabs 'realms'
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
    end
  end

  def new
    require_privilege(Privilege::CREATE, Realm)
    @realm = FrontendRealm.new
    load_backend_realms
  end

  def edit
    require_privilege(Privilege::MODIFY, Realm)
    @realm = FrontendRealm.find(params[:id])
    @title = @realm.name
    load_backend_realms
  end

  def update
    require_privilege(Privilege::MODIFY, Realm)
    @realm = FrontendRealm.find(params[:id])
    @title = @realm.name || t("realms.realm")

    if params[:commit] == "Reset"
      redirect_to edit_realm_url(@realm) and return
    end

    if @realm.update_attributes(params[:frontend_realm])
      flash[:notice] = t"realms.flash.notice.updated"
      redirect_to realms_url and return
    end

    load_backend_realms
    render :action => 'edit'
  end

  def create
    require_privilege(Privilege::CREATE, Realm)
    #@provider = Provider.find(params[:provider_id])
    @realm = FrontendRealm.new(params[:frontend_realm])
    if @realm.save
      flash[:notice] = t"realms.flash.notice.added"
      redirect_to realm_path(@realm)
    else
      load_backend_realms
      render :new
    end
  end

  def destroy
    require_privilege(Privilege::MODIFY, Realm)
    if FrontendRealm.destroy(params[:id])
      flash[:notice] = t "realms.flash.notice.deleted"
    else
      flash[:error] = t"realms.flash.error.not_deleted"
    end
    redirect_to realms_path
  end

  def multi_destroy
    deleted = []
    not_deleted = []
    if params[:realm_selected].blank?
      flash[:error] = t"realms.flash.error.select_to_delete"
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
      flash[:notice] = "#{t('realms.flash.notice.more_deleted')} #{deleted.join(', ')}"
    end
    unless not_deleted.empty?
      flash[:error] = "#{t('realms.flash.error.more_not_deleted')} #{not_deleted.join(', ')}"
    end
    redirect_to realms_path
  end

  def show
    @realm = FrontendRealm.find(params[:id])
    @title = @realm.name
    @tab_captions = [t('realms.tab_captions.properties'), t('realms.tab_captions.mapping')]
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]

    @backend_realm_targets = @realm.realm_backend_targets.select { |x| x.realm_or_provider_type == 'Realm' }
    @backend_provider_targets = @realm.realm_backend_targets.select { |x| x.realm_or_provider_type == 'Provider' }

    save_breadcrumb(realm_path(@realm), @realm.name)
    load_backend_realms

    respond_to do |format|
      format.html { render :action => 'show' }
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab
      end
      format.json { render :json => @realm }
    end
  end

  def filter
    redirect_to_original({"realms_preset_filter" => params[:realms_preset_filter], "realms_search" => params[:realms_search]})
  end

  protected

  def load_backend_realms
    #TODO: list only realms user has permission on
    @backend_realms = Provider.list_for_user(current_user, Privilege::USE).collect do |provider|
      provider.realms
    end.flatten

    @providers = Provider.list_for_user(current_user, Privilege::USE)
  end

  def load_realms
    @header = [
      {:name => '', :sortable => false},
      {:name => t("realms.index.realm_name"), :sort_attr => :name},
    ]
    @realms = FrontendRealm.apply_filters(:preset_filter_id => params[:realms_preset_filter], :search_filter => params[:realms_search])
  end
end
