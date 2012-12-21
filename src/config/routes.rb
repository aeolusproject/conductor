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

  resource :user_sessions
  match 'login',       :to => 'user_sessions#new',     :as => 'login'
  match 'logout',      :to => 'user_sessions#destroy', :as => 'logout'
  match 'register',    :to => 'users#new',             :as => 'register'

  resource  'account', :to => 'users'

  resources :password_resets, :only => [:create, :edit, :update]
  resources :username_recoveries, :only => [:create]

  resources :templates
  resources :permissions do
    collection do
      get :list
      delete :multi_destroy
      post :multi_update
      post :filter
      post :filter_entities
      post :profile_filter
    end
  end


  resources :settings do
    collection do
      get :self_service
    end
  end
  resources :pools do
    delete :multi_destroy, :on => :collection
    post :filter, :on => :collection

    resources :deployables, :only => [:index]

    resource :provider_selection, :only => [:show] do
      resources :provider_priority_groups, :except => [:show]

      match ':strategy_name/toggle', :to => 'provider_selections#toggle_strategy', :as => 'toggle_strategy'
      match ':strategy_name/edit', :to => 'provider_selections#edit_strategy', :as => 'edit_strategy'
      match ':strategy_name/save_strategy_options', :to => 'provider_selections#save_strategy_options', :as => 'save_strategy_options'
    end
  end

  resources :deployments do
    collection do
      get 'multi_stop'
      delete :multi_destroy
      get 'launch_new'
      post 'launch_time_params'
      get 'launch_time_params'
      post 'overview'
      get 'check_name'
      get 'launch_from_catalog'
      post 'filter'
    end
    resources :instances
  end

  resources :instances do
    collection do
      get 'multi_stop'
      get 'multi_reboot'
      get 'remove_failed'
      get 'export_events'
      post 'filter'
    end
    member do
      get 'key'
      post 'stop'
      post 'reboot'
    end
    resources :instance_parameters
  end

  resources :image_imports

  resources :hardware_profiles do
    delete 'multi_destroy', :on => :collection
    post :filter, :on => :collection
    post :matching_provider_hardware_profiles, :on => :collection
    member do
      get 'edit_cost'
      get 'edit_cost_billing'
      put 'update_cost'
      put 'update_cost_billing'
    end
  end

  resources :providers do
    delete 'multi_destroy', :on => :collection
    post :filter, :on => :collection

    resources :provider_accounts do
      collection do
        delete 'multi_destroy'
        get 'set_selected_provider'
        post :filter
      end
    end
  end

  resources :provider_accounts, :only => :index

  resources :provider_types, :only => :index

  resources :users do
    delete 'multi_destroy', :on => :collection
    post :filter, :on => :collection
  end

  resources :user_groups do
    collection do
      delete 'multi_destroy'
      post :filter
    end
    member do
      get 'add_members'
      post 'add_members'
      delete 'remove_members'
      post 'filter_members'
    end
  end

  resources :logs do
    collection do
      post 'filter'
      get 'export_logs'
    end
  end

  resources :config_servers do
    member do
      get 'test'
    end
  end

  resources :roles do
    delete 'multi_destroy', :on => :collection
  end

  resources :pool_families do
    collection do
      delete 'multi_destroy'
      post 'add_provider_account'
    end
    member do
      get 'add_provider_accounts'
      post 'add_provider_accounts'
      post 'remove_provider_accounts'
    end
  end

  resources :frontend_realms do
    delete 'multi_destroy', :on => :collection
    post :filter, :on => :collection
  end

  resources :provider_realms do
    post :filter, :on => :collection
  end

  resources :realm_mappings do
    delete 'multi_destroy', :on => :collection
  end

  resources :catalogs do
    delete 'multi_destroy', :on => :collection
    post 'create'
    post :filter, :on => :collection
    resources :deployables do
      collection do
        delete 'multi_destroy'
        post :filter
      end
      member do
        get :definition
      end
    end
  end

  resources :catalog_entries

  resources :deployables do
    collection do
      delete 'multi_destroy'
      post :filter
    end
    member do
      get :definition
    end
  end

  resources :images do
    member do
      post 'rebuild_all'
      post 'push_all'
      get 'template'
    end
    collection do
      post 'edit_xml'
      post 'overview'
      delete 'multi_destroy'
      post 'import'
    end
    resources :target_images
    resources :provider_images
  end

  get 'api', :controller => 'api/entrypoint', :action => 'index'
  namespace :api do
    resources :images do
      resources :builds
    end
    resources :builds do
      resources :target_images
    end

    resources :target_images do
      resources :provider_images
    end

    resources :provider_images
   # :except => [:new, :edit]

    resources :hooks

    resources :environments do
      resources :images
    end
  end

  scope "/api", :as => 'api' do
    resources :providers, :only => [:index, :show, :create, :update, :destroy] do
      resources :provider_accounts, :only => [:index, :create]
    end
    resources :provider_accounts, :only => [:index, :create, :show, :update, :destroy]
    resources :provider_types, :only => [:index, :show, :destroy]
    resources :hardware_profiles, :only => [:index, :show, :destroy, :create]
    resources :pools, :only => [:index, :show, :create, :update, :destroy] do
      resources :deployments, :only => [:index]
      resources :deployables, :only => [:index]
    end
    resources :pool_families, :only => [:index, :show, :create, :update, :destroy] do
      resources :provider_accounts, :controller => "pool_families_to_provider_accounts_associations", :only => [:index, :show, :update, :destroy]
    end
    resources :catalogs, :only => [:index, :show, :create, :update, :destroy] do
      resources :deployables, :only => [:index]
    end
    resources :deployments, :only => [:index, :show] do
      resources :instances, :only => [:index]
    end
    resources :deployables, :only => [:index, :show, :destroy]
    resources :provider_realms, :only => [:index, :show]
    resources :instances, :only => [:index, :show]
  end

  #match 'matching_profiles', :to => '/hardware_profiles/matching_profiles/:hardware_profile_id/provider/:provider_id', :controller => 'hardware_profiles', :action => 'matching_profiles', :conditions => { :method => :get }, :as =>'matching_profiles'
  match     'dashboard', :to => 'dashboard', :as => 'dashboard'
  root      :to => "pools#index"

  match '/:controller(/:action(/:id))'
end
