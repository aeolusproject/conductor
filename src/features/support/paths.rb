module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      '/'

    when /the new account page/
      register_path

    when /the login page/
      login_path

    when /^(.*)'s user page$/i
       admin_user_path(User.find_by_login($1))

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

    when /the settings page/
      settings_path

    when /the pools page/
      resources_pools_path

    when /the new pool page/
      new_pool_path

    when /the show pool page/
      pool_path

    when /the pool realms page/
      pool_realms_path

    when /the dashboard page/
      dashboard_path

    when /the instances page/
      resources_instances_path

    when /the new instance page/
      new_resources_instance_path

    when /the pool hardware profiles page/
      hardware_profiles_pool_path

    when /the permissions page/
      url_for :action => 'list', :controller => 'permissions', :only_path => true

    when /the new permission page/
      url_for :action => 'new', :controller => 'permissions', :only_path => true

    when /the new template page/
      url_for new_template_path

    when /the new template build page/
      url_for new_build_path

    when /the template builds page/
      url_for builds_path

    when /the templates page/
      templates_path

    when /the create template page/
      url_for create_template_path

    when /the self service settings page/
      url_for :action => 'self_service', :controller => 'settings', :only_path => true

    when /the settings update page/
      url_for :action => 'update', :controller => 'settings', :only_path => true

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
