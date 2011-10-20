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

SimpleNavigation::Configuration.run do |navigation|
  navigation.autogenerate_item_ids = false
  navigation.items do |first_level|
    first_level.dom_class = 'container'
    first_level.item :monitor, t('navigation.first_level.monitor'), pools_path, :class => 'monitor', :link => { :id => 'monitor' }, :highlights_on => /\/deployments|\/pools|\/instances|\/\z/
    first_level.item :administer, t('navigation.first_level.administer'), users_path, :class => 'administer' do |second_level|
      second_level.item :users_and_groups, t('navigation.second_level.users_groups'), users_path, :link => { :class => 'users' }, :highlights_on => /\/users|\/roles|\/permissions|\/account/
      second_level.item :environments, t('navigation.second_level.environments'), pool_families_path, :link => { :class => 'environments' }, :highlights_on => /\/pool_families/
      second_level.item :content, t('navigation.second_level.content'), catalogs_path, :link => { :class => 'content' }, :highlights_on => /\/catalogs|\/catalog_entries|\/realms|\/hardware_profiles|\/realm_mappings/
      second_level.item :cloud_providers, t('navigation.second_level.cloud_providers'), providers_path, :link => { :class => 'providers' }, :highlights_on => /\/providers/
      second_level.item :settings, t('navigation.second_level.settings'), settings_path, :link => { :class => 'settings'}, :highlights_on => /\/settings/
    end
  end
end
