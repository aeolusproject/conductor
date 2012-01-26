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

class RealmMappingsController < ApplicationController
  before_filter :require_user

  def new
    require_privilege(Privilege::MODIFY, Realm)
    @realm_target = RealmBackendTarget.new(:frontend_realm_id => params[:frontend_realm_id], :realm_or_provider_type => params[:realm_or_provider_type])
    load_backend_targets
  end

  def create
    require_privilege(Privilege::MODIFY, Realm)
    @realm_target = RealmBackendTarget.new(params[:realm_backend_target])
    if @realm_target.save
      flash[:notice] = t"realms.flash.notice.added_mapping"
      redirect_to realm_path(@realm_target.frontend_realm, :details_tab => 'mapping') and return
      #redirect_to realms_path and return
    end

    load_backend_targets
    render :new
  end

  def multi_destroy
    require_privilege(Privilege::MODIFY, Realm)
    if params[:id].blank?
      flash[:error] = t"realms.flash.error.select_to_delete_mapping"
      redirect_to realm_path(params[:frontend_realm_id], :details_tab => 'mapping')
    else
      # TODO: add permissions checks
      destroyed = RealmBackendTarget.destroy(params[:id])
      redirect_to realm_path(destroyed.first.frontend_realm_id, :details_tab => 'mapping')
    end
  end

  protected

  def load_backend_targets
    @backend_targets = if @realm_target.realm_or_provider_type == 'Realm'
      Realm.scan_for_new
      Realm.all
    else
      Provider.list_for_user(current_user, Privilege::VIEW)
    end

  end
end
