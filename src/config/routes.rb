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

Conductor::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)
  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

  resource :user_session
  match 'login',       :to => 'user_sessions#new',     :as => 'login'
  match 'logout',      :to => 'user_sessions#destroy', :as => 'logout'
  match 'register',    :to => 'users#new',             :as => 'register'

  resource  'account', :to => 'users'
  resources :templates, :builds
  resources :permissions do
    collection do
      get :list
    end
  end

  resources :settings do
    collection do
      get :self_service
      get :general_settings
    end
  end
  resources :pools do
    get :hardware_profiles
    get :realms
    delete :multi_destroy, :on => :collection
  end

  resources :deployments do
    collection do
      get 'multi_stop'
      delete :multi_destroy
      get 'launch_new'
      get 'check_name'
    end
    resources :instances
  end

  resources :instances do
    collection do
      get 'start'
      get 'multi_stop'
      get 'remove_failed'
      get 'export_events'
    end
    member do
      get 'key'
    end
  end

  resources :image_imports

  resources :hardware_profiles do
    delete 'multi_destroy', :on => :collection
  end

  resources :providers do
    delete 'multi_destroy', :on => :collection

    resources :provider_accounts
    resources :realms
    resources :hardware_profiles
  end

  resources :provider_types, :only => :index

  resources :users do
    delete 'multi_destroy', :on => :collection
  end

  resources :provider_accounts do
    collection do
      delete 'multi_destroy'
      get 'set_selected_provider'
    end
  end

  resources :roles do
    delete 'multi_destroy', :on => :collection
  end

  resources :settings do
    collection do
      get 'self_service'
      get 'general_settings'
    end
  end

  resources :pool_families do
    collection do
      delete 'multi_destroy'
      post 'add_provider_account'
      delete 'multi_destroy_provider_accounts'
    end
  end

  resources :realms do
    delete 'multi_destroy', :on => :collection
  end

  resources :realm_mappings do
    delete 'multi_destroy', :on => :collection
  end

  resources :catalog_entries do
    delete 'multi_destroy', :on => :collection
  end

  resources :catalogs do
    delete 'multi_destroy', :on => :collection
    post 'create'
  end

  #match 'matching_profiles', :to => '/hardware_profiles/matching_profiles/:hardware_profile_id/provider/:provider_id', :controller => 'hardware_profiles', :action => 'matching_profiles', :conditions => { :method => :get }, :as =>'matching_profiles'
  match     'dashboard', :to => 'dashboard', :as => 'dashboard'
  root      :to => "pools#index"

  match '/:controller(/:action(/:id))'
end
