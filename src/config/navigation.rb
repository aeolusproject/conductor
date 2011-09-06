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
    first_level.item :monitor, t(:monitor), pools_path, :class => 'monitor', :highlights_on => lambda { ["pools" ,"deployments", "instances"].include? controller_name }
    first_level.item :administer, t(:administer), users_path, :class => 'administer', :highlights_on => /\/admin/ do |second_level|
      second_level.item :users_and_groups, "Users & Groups", users_path, :link => { :class => 'users' }, :highlights_on => /\/users/
      second_level.item :environments, "Environments", hardware_profiles_path, :link => { :class => 'environments' }, :highlights_on => /\/users/
      second_level.item :content, "Content", realms_path, :link => { :class => 'content' }, :highlights_on => /\/users/
      second_level.item :cloud_providers, "Cloud Providers", edit_provider_path(Provider.first), :link => { :class => 'providers' }, :highlights_on => /\/providers/
    end
  end
end
