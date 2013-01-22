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

class SettingsController < ApplicationController
  before_filter :require_user

  def index
    clear_breadcrumbs
    save_breadcrumb(settings_path(:viewstate => viewstate_id))
  end

  # Settings MetaData Keys
  SELF_SERVICE_DEFAULT_QUOTA = "self_service_default_quota"
  KEYS = [SELF_SERVICE_DEFAULT_QUOTA]

  def self_service
    require_privilege(Privilege::MODIFY)
    @self_service_default_quota = MetadataObject.lookup(SELF_SERVICE_DEFAULT_QUOTA)
  end

  def update
    KEYS.each do |key|
      if params[key]
        if key == SELF_SERVICE_DEFAULT_QUOTA
          @self_service_default_quota = MetadataObject.lookup(key)
          if !@self_service_default_quota.update_attributes(params[key])
            flash[:warning] = _("Could not update the default quota")
            render :self_service
            return
          end
        elsif key == SELF_SERVICE_DEFAULT_POOL
          if Pool.exists?(params[key])
            MetadataObject.set(key, Pool.find(params[key]))
          end
        elsif key == SELF_SERVICE_DEFAULT_ROLE
          if Role.exists?(params[key])
            MetadataObject.set(key, Role.find(params[key]))
          end
        else
          MetadataObject.set(key, params[key])
        end
      end
    end
    flash[:notice] = _("Settings Updated")
    redirect_to :action => 'self_service'
  end

end
