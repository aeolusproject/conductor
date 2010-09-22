SimpleNavigation::Configuration.run do |navigation|
  navigation.autogenerate_item_ids = false
  navigation.items do |first_level|
    first_level.item :operation, t(:operation), '', :class => 'operation' do |second_level|
      second_level.item :monitor, t(:monitor), '/dashboard'
      second_level.item :browse_objects, t(:browse_objects), '/browse_objects', :class => 'disabled'
    end
    first_level.item :administration, t(:administration), '', :class => 'administration' do |second_level|
      second_level.item :system_settings, t(:system_settings), "/settings" do |third_level|
        third_level.item :manage_providers, t(:manage_providers), "/provider" do |fourth_level|
          fourth_level.item :provider_summary, t(:provider_summary), "/provider/show"
          fourth_level.item :provider_accounts, t(:provider_accounts), "/provider/accounts"
        end
        third_level.item :self_service_settings, t(:self_service_settings), "/settings/self-service"
        third_level.item :manage_users, t(:manage_users), "/users" do |fourth_level|
          fourth_level.item :new_user, t(:new_user), '/account/edit'
          fourth_level.item :edit_user, t(:edit_user), '/account/edit'
        end
      end
      second_level.item :pools_and_zones, t(:pools_and_zones), '/pool' do |third_level|
        third_level.item :new_pool, t(:new_pool), '/pool/new'
        third_level.item :edit_pool, t(:edit_pool), '/pool/edit'
      end
      second_level.item :audit_report, t(:audit_report), '/audit_report', :class => 'disabled'
      second_level.item :assistance_requests, t(:assistance_requests), '/assistance_requests', :class => 'disabled'
    end
    first_level.item :build, t(:build), '', :class => 'build' do |second_level|
      second_level.item :templates, t(:templates), '/templates' do |third_level|
        third_level.item :basic_template, t(:basic_template), '/templates/new' do |fourth_level|
          fourth_level.item :browse_packages, t(:browse_packages), '/templates/packages'
        end
      end
      second_level.item :grinds, t(:grinds), '/templates/builds'
      second_level.item :images, t(:images), '/image/show'
    end
    first_level.item :runtime, t(:runtime), '', :class => 'runtime' do |second_level|
      second_level.item :instance_management, t(:instance_management), '/instance' do |third_level|
        third_level.item :instance_details, t(:instance_details), '/instance/show'
        third_level.item :launch_instance, t(:launch_instance), '/instance/new'
      end
    end
    first_level.item :help, t(:help), '/help', :id => 'help'
  end
end
