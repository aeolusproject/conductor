module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /^the home\s?page$/
      '/'

    when /the new account page/
      register_path

    when /the login page/
      login_path

    when /^(.*)'s user page$/i
       user_path(User.find_by_login($1))

    when /^(.*)'s role page$/i
       role_path(Role.find_by_name($1))

    when /^(.*)'s realm page$/i
       realm_path(FrontendRealm.find_by_name($1))

    when /the account page/
      account_path

    when /the login error page/
      user_session_path

    when /the providers page/
      url_for :controller => 'providers', :action => 'index', :only_path => true

    when /the new provider page/
      url_for :controller => 'providers', :action => 'new', :only_path => true

    when /the show provider page/
      url_for :controller => 'providers', :action => 'show', :only_path => true

    when /the provider settings page/
      url_for :controller => 'providers', :action => 'settings', :only_path => true

    when /^the (.*)'s edit provider page$/
      edit_provider_path(Provider.find_by_name($1))

    when /the settings page/
      settings_path

    when /the pools page/
      pools_path

    when /the new pool page/
      new_pool_path

    when /the show pool page/
      pool_path

    when /the page for the pool "([^"]*)"/
      pool_path(Pool.find_by_name($1))

    when /the pool realms page/
      pool_realms_path

    when /the deployments page/
      deployments_path

    when /the instances page/
      instances_path

    when /the new instance page/
      new_instance_path

    when /the pool hardware profiles page/
      hardware_profiles_pool_path

    when /the permissions page/
      url_for list_permissions_path

    when /the new permission page/
      url_for new_permission_path

    when /the pool family provider accounts page/
      url_for pool_family_path(@pool_family, :details_tab => 'provider_accounts')

    when /the self service settings page/
      url_for :action => 'self_service', :controller => 'settings', :only_path => true

    when /the settings update page/
      url_for :action => 'update', :controller => 'settings', :only_path => true

    when /the hardware profiles page/
      url_for hardware_profiles_path

    when /the new hardware profile page/
      url_for new_hardware_profile_path

    when /^(.*)'s edit hardware profile page$/
      edit_hardware_profile_path(HardwareProfile.find_by_name($1))

    when /^(.*)'s provider account page$/
      provider_account_path(ProviderAccount.find_by_label($1))

    when /the operational status of deployment page/
      deployment_path(@deployment, :details_tab => 'operation')

    when /^(.*)'s edit deployment page$/
      edit_deployment_path(Deployment.find_by_name($1))

    when /^(.*)'s edit instance page$/
      edit_instance_path(Instance.find_by_name($1))

    when /^(.*)'s instance page$/
      instance_path(Instance.find_by_name($1))

    when /^(.*)'s deployment page$/
      deployment_path(Deployment.find_by_name($1))

    when /^the "(.*)" pool filter view page$/
      pool = Pool.find_by_name($1)
      pool_path(pool, :view => 'filter')

    when /^the my user page$/
      user_path(user) #(User.find_by_login($1))

    when /^the (.*)'s edit user page$/
      edit_user_path(User.find_by_login($1))


    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /^the (.*) page$/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue NoMethodError, ArgumentError
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
