#
#   Copyright 2013 Red Hat, Inc.
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

Alberich::PermissionsController.class_eval do
  def filter
    redirect_to_original({"permissions_preset_filter" => params[:permissions_preset_filter], "permissions_search" => params[:permissions_search]})
  end

  def filter_entities
    redirect_to_original({"entities_preset_filter" => params[:entities_preset_filter], "entities_search" => params[:entities_search]})
  end

  def profile_filter
    entity = Alberich::Entity.find(params[:entity_id]).entity_target
    path = entity.is_a?(User) ? "user_path" : "user_group_path"
    redirect_to main_app.send( path, entity,
                 "profile_permissions_preset_filter" =>
                 params[:profile_permissions_preset_filter],
                 "profile_permissions_search" =>
                 (params[:profile_permissions_preset_filter].empty? ?
                  nil : params[:profile_permissions_search]))
  end

  def load_entities
    sort_order = params[:sort_by].nil? ? "name" : params[:sort_by]
    @entities = paginate_collection(Alberich::Entity.
      order(sort_column(Alberich::Entity, sort_order)).
      apply_filters(:preset_filter_id => params[:entities_preset_filter],
                    :search_filter => params[:entities_search]),
                                    params[:page])
  end

  def global_permission_ui_hook
    set_admin_users_tabs 'permissions'
  end
end
