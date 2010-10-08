SimpleNavigation::Configuration.run do |navigation|
  navigation.autogenerate_item_ids = false
  navigation.items do |first_level|
    first_level.item :operation, t(:operation), '#', :class => 'operation' do |second_level|
      second_level.item :monitor, t(:monitor), :controller => 'dashboard'
      second_level.item :browse_objects, t(:browse_objects), '#', :class => 'disabled'
    end
    first_level.item :administration, t(:administration), '#', :class => 'administration' do |second_level|
      second_level.item :system_settings, t(:system_settings), :controller => 'settings' do |third_level|
        third_level.item :manage_providers, t(:manage_providers), :controller => 'provider' do |fourth_level|
          fourth_level.item :provider_summary, t(:provider_summary), { :controller => 'provider', :action => 'show', :id => (@provider.id if @provider) }, :highlights_on => /\/provider\/(show|edit|new)/
          fourth_level.item :provider_accounts, t(:provider_accounts), { :controller => 'provider', :action => 'accounts', :id => (@provider.id if @provider) }, :highlights_on => /\/provider\/accounts/
        end
        #third_level.item :self_service_settings, t(:self_service_settings), :controller => 'settings', :action => 'self_service'
        third_level.item :define_services, t(:define_services), '#'
        third_level.item :define_services, t(:define_profiles), '#'
        third_level.item :define_services, t(:define_locales), '#'
        third_level.item :manage_users, t(:manage_users), :controller => 'users' do |fourth_level|
          fourth_level.item :new_user, t(:new_user), {:controller => 'users', :action => 'new'}, :highlights_on => /\/users\/new/
          fourth_level.item :edit_user, t(:edit_user), {:controller => 'users', :action => 'edit'},  :highlights_on => /\/users\/edit/
        end
        third_level.item :define_services, t(:permissions), '#'
        third_level.item :general_settings, t(:general_settings), '#'
      end
      second_level.item :pools_and_zones, t(:pools_and_zones), :controller => 'pools' do |third_level|
        third_level.item :new_pool, t(:new_pool), :controller => 'pools', :action => 'new'
        third_level.item :edit_pool, t(:edit_pool), :controller => 'pools', :action => 'edit'
      end
      second_level.item :audit_report, t(:audit_report), '#', :class => 'disabled'
      second_level.item :assistance_requests, t(:assistance_requests), '#', :class => 'disabled'
    end
    first_level.item :define, t(:define), '#', :class => 'build' do |second_level|
      second_level.item :deployables, t(:deployables), :controller => 'templates' do |third_level|
        third_level.item :basic_template, t(:basic_template), :controller => 'templates', :action => 'new' do |fourth_level|
          fourth_level.item :browse_packages, t(:browse_packages), :controller => 'templates', :action => 'packages'
        end
      end
      second_level.item :builds, t(:builds), :controller => 'templates', :action => 'builds'
      second_level.item :images, t(:images), '#', :class => 'disabled'
    end
    first_level.item :runtime, t(:runtime), '#', :class => 'runtime' do |second_level|
      second_level.item :instance_management, t(:instance_management), :controller => 'instance'
    end
    first_level.item :help, t(:help), '#', :id => 'help', :class => "disabled"
  end
end
