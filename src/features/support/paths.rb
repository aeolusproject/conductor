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

    when /the provider list page/
      '/'

    when /the login page/
      login_path

    when /^(.*)'s user page$/i
       user_path(User.find_by_login($1))

    when /the account page/
      account_path

    when /the login error page/
      user_session_path

    when /the new provider page/
      new_provider_path

    when /the new pool page/
      new_pool_path

    when /the show pool page/
      pool_path

    when /the pool realms page/
      pool_realms_path

    when /the dashboard page/
      dashboard_path

    when /the instances page/
      instance_path

    when /the pool hardware profiles page/
      hardware_profiles_pool_path

    when /the permissions page/
      url_for :action => 'list', :controller => 'permissions', :only_path => true

    when /the new permission page/
      url_for :action => 'new', :controller => 'permissions', :only_path => true

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
