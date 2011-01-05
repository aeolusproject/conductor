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
    r.resources :pools, :deployments
    r.resources :instances, :collection => {:start => :get, :stop => :get, :select_template => :get, :remove_failed => :get}, :member => {:key => :get}
  end

  map.namespace 'image_factory' do |r|
    r.resources :assemblies, :deployables
    r.resources :templates, :collection => {:collections => :get, :add_selected => :get, :metagroup_packages => :get, :remove_package => :get, :multi_destroy => :delete}
    r.resources :builds
  end

  map.connect '/set_layout', :controller => 'application', :action => 'set_layout'

  map.namespace 'admin' do |r|
    r.resources :hardware_profiles, :pool_families, :provider_accounts, :realms, :settings
    r.resources :providers, :collection => { :multi_destroy => :delete }
    r.resources :users, :collection => { :multi_destroy => :delete }
    r.resources :provider_accounts, :collection => { :multi_destroy => :delete }
    r.resources :roles, :collection => { :multi_destroy => :delete }
  end

  map.resources :pools

  map.connect '', :controller => 'dashboard'

  map.login 'login', :controller => "user_sessions", :action => "new"
  map.logout 'logout', :controller => "user_sessions", :action => "destroy"
  map.resource :user_session
  map.register 'register', :controller => 'users', :action => 'new'
  map.resource :account, :controller => "users"
  map.resources :users

  map.dashboard '/dashboard', :controller => 'dashboard'
  map.instance '/instances', :controller => 'instances'
  # map.templates '/templates', :controller => 'templates'
  map.settings '/settings', :controller => 'settings'
  map.root  :dashboard

  # Temporarily disable this route, provider stuff is not restful yet.
  # Will be re-enabled in upcoming patch
  map.resources :providers do |provider|
    provider.resources :accounts, :controller => 'cloud_accounts'
  end
  map.destroy_providers_account '/providers/:provider_id/accounts/:id/destroy', :controller => 'cloud_accounts', :action => 'destroy', :conditions => { :method => :get }

  map.resources :templates, :collection => { :destroy_multiple => :get },
    :member => {
      :assembly => :get,
      :deployment_definition => :get,
      :action => :get,
    }
  map.resources :builds

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
