SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |first_level|
    first_level.item :old_nav, "Old Navigation", "#" do |old_nav|
      old_nav.dom_class = 'nav'
      old_nav.item :dashboard, t(:dashboard), :controller => "dashboard"
      old_nav.item :instances, t(:instances), :controller => "instance"
      old_nav.item :templates, t(:templates), :controller => "image", :action => "show"
      old_nav.item :users, t(:users), {:controller => "users"}, :if => lambda {
        @current_user && has_view_perms?(BasePermissionObject.general_permission_scope) }
      old_nav.item :settings, t(:settings), :controller => "settings"
    end

    first_level.item :operate, t(:operate), '#' do |second_level|
      second_level.item :monitor, t(:monitor), '/dashboard'
    end
    first_level.item :administer, t(:administer), '#' do |second_level|
      second_level.item :system_settings, t(:system_settings), "/settings" do |third_level|
        third_level.item :manage_providers, t(:manage_providers), "/provider" do |fourth_level|
          fourth_level.item :provider_summary, t(:provider_summary), "/provider/show"
          fourth_level.item :provider_accounts, t(:provider_accounts), "/provider/accounts"
        end
        third_level.item :self_service_settings, t(:self_service_settings), "/settings/self-service"
        third_level.item :manage_users, t(:manage_users), "/users" , :if => lambda { @current_user && has_view_perms?(BasePermissionObject.general_permission_scope) } do |fourth_level|
          fourth_level.item :new_user, t(:new_user), '/account/edit'
          fourth_level.item :edit_user, t(:edit_user), '/account/edit'
        end
      end
      second_level.item :new_pool, t(:new_pool), '/pool/new', :if => lambda { true }
      second_level.item :edit_pool, t(:edit_pool), '/pool/edit', :if => lambda { true }
    end
    first_level.item :build, t(:build), '#' do |second_level|
      second_level.item :template_management, t(:template_management), '/templates' do |third_level|
        third_level.item :basic_template, t(:basic_template), '/templates/new' do |fourth_level|
          fourth_level.item :browse_packages, t(:browse_packages), '/templates/packages'
        end
      end
      second_level.item :grind_management, t(:grind_management), '/templates/builds'
    end
    first_level.item :run, t(:run), '#' do |second_level|
      second_level.item :manage_instances, t(:manage_instances), '/instance' do |third_level|
        third_level.item :instance_details, t(:instance_details), '/instance/show'
        third_level.item :launch_instance, t(:launch_instance), '/instance/new'
      end
    end
  end
end
