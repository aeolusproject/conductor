#
# Copyright (C) 2009 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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

ActionController::Routing::Routes.draw do |map|

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up ''
  # -- just remember to delete public/index.html.

  map.resources :pools, :collection => { :multi_destroy => :delete }
  map.resources :deployments, :collection  => { :multi_stop => :get, :launch_new => :get }
  map.resources :instances, :collection => {:start => :get, :multi_stop => :get, :select_template => :get, :remove_failed => :get, :can_start => :get, :can_create => :get }, :member => {:key => :get}

  map.can_start_instance '/instances/:instance_id/can_start/:provider_account_id', :controller => 'instances', :action => 'can_start', :conditions => { :method => :get }
  map.can_create_instance '/instances/:instance_id/can_create/:provider_account_id', :controller => 'instances', :action => 'can_create', :conditions => { :method => :get }

  map.resources :assemblies
  map.resources :image_imports
  map.resources :deployables, :collection => { :multi_destroy => :delete }, :member => { :pick_assemblies => :get, :remove_assemblies => :delete, :add_assemblies => :put, :launch => :post }
  map.resources :templates, :collection => {:collections => :get, :add_selected => :get, :metagroup_packages => :get, :remove_package => :get, :multi_destroy => :delete}
  map.connect "/builds/update_status.:format", :controller => :builds, :action => :update_status
  map.resources :builds, :collection => { :delete => :delete, :upload => :get, :retry => :post }

  map.resources :hardware_profiles, :collection => { :multi_destroy => :delete }
  map.resources :providers, :collection => { :multi_destroy => :delete }
  map.resources :users, :collection => { :multi_destroy => :delete }
  map.resources :provider_accounts, :collection => { :multi_destroy => :delete, :set_selected_provider => :get}
  map.resources :roles, :collection => { :multi_destroy => :delete }
  map.resources :settings, :collection => { :self_service => :get, :general_settings => :get }
  map.resources :pool_families, :collection => { :multi_destroy => :delete, :add_provider_account => :post, :multi_destroy_provider_accounts => :delete }
  map.resources :realms, :collection => { :multi_destroy => :delete }
  map.resources :realm_mappings, :collection => { :multi_destroy => :delete }

  map.matching_profiles '/hardware_profiles/matching_profiles/:hardware_profile_id/provider/:provider_id', :controller => 'hardware_profiles', :action => 'matching_profiles', :conditions => { :method => :get }

  map.login 'login', :controller => "user_sessions", :action => "new"
  map.logout 'logout', :controller => "user_sessions", :action => "destroy"
  map.resource :user_session
  map.register 'register', :controller => 'users', :action => 'new'
  map.resource :account, :controller => "users"
  map.resources :permissions, :collection => { :list => :get }

  map.root :controller => 'deployments'


  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
