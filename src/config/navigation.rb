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

SimpleNavigation::Configuration.run do |navigation|
  navigation.autogenerate_item_ids = false
  navigation.items do |first_level|
    first_level.dom_class = 'container'
    first_level.item :monitor, t('navigation.first_level.monitor'), main_app.pools_path, :class => 'monitor', :link => { :id => 'monitor' }, :highlights_on => /\/deployments|\/pools$|\/pools\/\d$|\/pools\?|\/instances|\/logs|\/\z/
    first_level.item :administer, t('navigation.first_level.administer'), main_app.users_path, :class => 'administer' do |second_level|
      second_level.item :users, t('navigation.second_level.users'), main_app.users_path, :link => { :class => 'users' }, :highlights_on => /\/users|\/user_groups|\/roles|\/permissions|\/account/
      second_level.item :environments, t('navigation.second_level.environments'), main_app.pool_families_path, :link => { :class => 'environments' }, :highlights_on => /\/pool_families|\/images|\/pools\/\d\/provider_selection/
      second_level.item :content, t('navigation.second_level.content'), main_app.catalogs_path, :link => { :class => 'content' }, :highlights_on => /\/catalogs|\/catalog_entries|\/realms|\/hardware_profiles|\/realm_mappings|\/deployables/
      second_level.item :cloud_providers, t('navigation.second_level.cloud_providers'), main_app.providers_path, :link => { :class => 'providers' }, :highlights_on => /\/providers|\/provider_realms|\/config_servers/
      second_level.item :settings, t('navigation.second_level.settings'), main_app.settings_path, :link => { :class => 'settings'}, :highlights_on => /\/settings/
    end
  end
end
