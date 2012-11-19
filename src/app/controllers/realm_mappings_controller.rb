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
    require_privilege(Privilege::MODIFY, FrontendRealm)
    @title = _("Create a new Realm Mapping")
    @realm_target = RealmBackendTarget.new(:frontend_realm_id => params[:frontend_realm_id], :provider_realm_or_provider_type => params[:provider_realm_or_provider_type])
    load_backend_targets
  end

  def create
    require_privilege(Privilege::MODIFY, FrontendRealm)
    @realm_target = RealmBackendTarget.new(params[:realm_backend_target])
    if @realm_target.save
      flash[:notice] = _("Realm mapping was added.")
      redirect_to frontend_realm_path(@realm_target.frontend_realm, :details_tab => 'mapping')
    else
      @title = _("Create a new Realm Mapping")
      load_backend_targets
      render :new
    end
  end

  def multi_destroy
    require_privilege(Privilege::MODIFY, FrontendRealm)
    if params[:id].blank?
      flash[:error] = _("You must select at least one mapping to delete.")
      redirect_to frontend_realm_path(params[:frontend_realm_id], :details_tab => 'mapping')
    else
      # TODO: add permissions checks
      destroyed = RealmBackendTarget.destroy(params[:id])
      redirect_to frontend_realm_path(destroyed.first.frontend_realm_id, :details_tab => 'mapping')
    end
  end

  protected

  def load_backend_targets
    @backend_targets = if @realm_target.provider_realm_or_provider_type == 'ProviderRealm'
      Provider.list_for_user(current_session, current_user,
                             Privilege::USE).collect do |provider|
        provider.provider_realms
      end.flatten
    else
      Provider.list_for_user(current_session, current_user, Privilege::USE)
    end

  end
end
