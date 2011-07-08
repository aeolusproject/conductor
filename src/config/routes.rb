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

  #Do we still need this one? => resource :user_session
  match 'login',       :to => 'user_sessions#new',     :as => 'login'
  match 'logout',      :to => 'user_sessions#destroy', :as => 'logout'
  match 'register',    :to => 'users#new',             :as => 'register'

  resource  'account', :to => 'users'
  resources :users, :instances, :templates, :builds
  resources :permissions, :collection => { :list => :get}
  resources :settings do
    collection do
      get :self_service
      get :general_settings
    end
  end
  resources :pools do
    get :hardware_profiles
    get :realms
  end

  resources :pools, :collection => { :multi_destroy => :delete }
  resources :deployments, :collection  => { :multi_stop => :get, :launch_new => :get, :check_name => :get }
  resources :instances, :collection => {:start => :get, :multi_stop => :get, :remove_failed => :get, :can_start => :get, :can_create => :get }, :member => {:key => :get}

  #map.can_start_instance '/instances/:instance_id/can_start/:provider_account_id', :controller => 'instances', :action => 'can_start', :conditions => { :method => :get }
  #map.can_create_instance '/instances/:instance_id/can_create/:provider_account_id', :controller => 'instances', :action => 'can_create', :conditions => { :method => :get }

  resources :image_imports

  resources :hardware_profiles, :collection => { :multi_destroy => :delete }
  resources :providers, :collection => { :multi_destroy => :delete }
  #This may be the correct way to do the above now....
  #resources :providers do
  #  resources :accounts, :to => :cloud_accounts
  #end
  resources :provider_types, :only => :index
  resources :users, :collection => { :multi_destroy => :delete }
  resources :provider_accounts, :collection => { :multi_destroy => :delete, :set_selected_provider => :get}
  resources :roles, :collection => { :multi_destroy => :delete }
  resources :settings, :collection => { :self_service => :get, :general_settings => :get }
  resources :pool_families, :collection => { :multi_destroy => :delete, :add_provider_account => :post, :multi_destroy_provider_accounts => :delete }
  resources :realms, :collection => { :multi_destroy => :delete }
  resources :realm_mappings, :collection => { :multi_destroy => :delete }
  resources :suggested_deployables, :collection => { :multi_destroy => :delete }

  #match 'matching_profiles', :to => '/hardware_profiles/matching_profiles/:hardware_profile_id/provider/:provider_id', :controller => 'hardware_profiles', :action => 'matching_profiles', :conditions => { :method => :get }, :as =>'matching_profiles'
  match     'dashboard', :to => 'dashboard', :as => 'dashboard'
  root      :to => "pools#index"

  match '/:controller(/:action(/:id))'
end
