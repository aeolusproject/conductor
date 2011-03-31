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

  map.namespace 'resources' do |r|
    r.resources :pools, :collection => { :multi_destroy => :delete }
    r.resources :deployments
    r.resources :instances, :collection => {:start => :get, :multi_stop => :get, :select_template => :get, :remove_failed => :get, :can_start => :get, :can_create => :get }, :member => {:key => :get}
  end

  map.can_start_instance '/resources/instances/:instance_id/can_start/:provider_account_id', :controller => 'resources/instances', :action => 'can_start', :conditions => { :method => :get }
  map.can_create_instance '/resources/instances/:instance_id/can_create/:provider_account_id', :controller => 'resources/instances', :action => 'can_create', :conditions => { :method => :get }

  map.namespace 'image_factory' do |r|
    r.resources :assemblies
    r.resources :image_imports
    r.resources :deployables, :collection => { :multi_destroy => :delete }
    r.resources :templates, :collection => {:collections => :get, :add_selected => :get, :metagroup_packages => :get, :remove_package => :get, :multi_destroy => :delete}
    r.connect "/builds/update_status.:format", :controller => :builds, :action => :update_status
    r.resources :builds, :collection => { :delete => :delete, :upload => :get, :retry => :post }
  end

  map.namespace 'admin' do |r|
    r.resources :hardware_profiles, :collection => { :multi_destroy => :delete }
    r.resources :providers, :collection => { :multi_destroy => :delete }
    r.resources :users, :collection => { :multi_destroy => :delete }
    r.resources :provider_accounts, :collection => { :multi_destroy => :delete, :set_selected_provider => :get}

    r.resources :roles, :collection => { :multi_destroy => :delete }
    r.resources :settings, :collection => { :self_service => :get, :general_settings => :get }
    r.resources :pool_families, :collection => { :multi_destroy => :delete }
    r.resources :realms, :collection => { :multi_destroy => :delete }
    r.resources :realm_mappings, :collection => { :multi_destroy => :delete }
  end

  map.matching_profiles '/admin/hardware_profiles/matching_profiles/:hardware_profile_id/provider/:provider_id', :controller => 'admin/hardware_profiles', :action => 'matching_profiles', :conditions => { :method => :get }

  map.login 'login', :controller => "user_sessions", :action => "new"
  map.logout 'logout', :controller => "user_sessions", :action => "destroy"
  map.resource :user_session
  map.register 'register', :controller => 'admin/users', :action => 'new'
  map.resource :account, :controller => "admin/users"
  map.resources :permissions, :collection => { :list => :get }

  map.root :controller => 'resources/deployments'


  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
