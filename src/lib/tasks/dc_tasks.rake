namespace :dc do
  desc 'Create and register a new user'
  task :create_user, [:username, :password, :email, :first_name, :last_name] => :environment do |t, args|
    unless args.username && args.email && args.password
      puts "Usage: rake 'dc:create_user[username,password,email,first_name,last_name]'"
      exit(1)
    end

    user = User.find_by_username(args.username)

    if user
      puts "User already exists: #{args.username}"
      exit(1)
    end

    first_name = args.first_name.nil? ? "" : args.first_name
    last_name  = args.last_name.nil?  ? "" : args.last_name

    user = User.new(:username => args.username, :email => args.email,
                    :password => args.password,
                    :password_confirmation => args.password,
                    :first_name => first_name,
                    :last_name  => last_name,
                    :quota => Quota.new)
    registration = RegistrationService.new(user)
    if registration.save
      puts "User #{args.username} registered"
    else
      puts "User registration failed: #{registration.error}"
    end
  end

  desc 'Destroy an existing user'
  task :destroy_user, [:username] => :environment do |t, args|
    unless args.username
      puts "Usage: rake 'dc:destroy_user[username]'"
      exit(1)
    end

    user = User.find_by_username(args.username)

    if !user
      puts "User not found: #{args.username}"
      exit(1)
    elsif user.destroy
      puts "User #{args.username} destroyed"
    else
      puts "User destruction failed: #{args.username}"
      exit(1)
    end
  end

  desc 'Destroy users matching a pattern'
  task :destroy_users_by_pattern, [:pattern] => :environment do |t, args|
    unless args.pattern
      puts "Usage: rake 'dc:destroy_users_by_pattern[pattern]'"
      exit(1)
    end

    users = User.find(:all, :conditions => ["username LIKE ?", args.pattern])

    if users.empty?
      puts "No users match pattern: #{args.pattern}"
      exit(0)
    end

    users.each do |user|
      if user.destroy
        puts "User #{user.username} destroyed"
      else
        puts "User destruction failed: #{user.username}"
        exit(1)
      end
    end
  end

  desc 'Create and register a list of ldap users, separated by ":"'
  task :create_ldap_users, [:usernames] => :environment do |t, args|
    unless args.usernames
      puts "Usage: rake 'dc:create_ldap_users[username1:username2:...]'"
      exit(1)
    end

    args.usernames.split(":").each do |username|
      user = User.find_by_username(args.username)

      if user
        puts "User already exists: #{username}"
      end

      begin
        user = User.create_ldap_user!(username)
        puts "User #{username} registered"
      rescue Exception => e
        puts "User registration failed: #{e}"
      end
    end
  end


  desc 'Grant administrator privileges to registred user'
  task :site_admin, [:username] => :environment do |t, args|
    unless args.username
      puts "Usage: rake dc:site_admin[user]"
      exit(1)
    end

    user = User.find_by_username(args.username)

    unless user
      puts "Unknown user: #{args.username}"
      exit(1)
    end

    unless user.permissions.select { |p| p.role.name.eql?('base.admin') }.empty?
      puts "Permission already granted for user #{args.username}"
      exit(1)
    end
    permission = Permission.new(:role => Role.find_by_name('base.admin'),
                                :permission_object => BasePermissionObject.general_permission_scope,
                                :entity => user.entity)
    if permission.save
      puts "Granting administrator privileges for #{args.username}..."
    else
      puts "Granting administrator privileges for #{args.username} failed #{permission.errors.to_xml}"
      exit(1)
    end
  end


  desc 'Create user "admin" for CloudEngine'
  task :create_admin_user => :environment do
    Rake::Task[:'dc:create_user'].invoke('admin', 'password', 'admin@aeolusproject.org', 'Administrator', 'Administrator')
    Rake::Task[:'dc:site_admin'].invoke('admin')
  end


  desc 'Setup CloudEngine and create admin user automatically'
  task :setup => :environment do
    print "Reset database to clean state (YES/no)? "
    STDOUT.flush
    drop_db = STDIN.gets.chomp
    unless drop_db.strip.eql?('no')
      Rake::Task[:'db:migrate:reset'].invoke

      # Reload model classes so that they reflect changes of model attributes
      # made by migrations.
      ActionDispatch::Reloader.cleanup!
      ActionDispatch::Reloader.prepare!

      Rake::Task[:'db:seed'].invoke
    end

    Rake::Task[:'dc:create_admin_user'].invoke
  end

  desc 'Generate keys for OAuth and create config/oauth.json'
  task :oauth_keys do
    oauth_config_file = "#{::Rails.root}/config/oauth.json"
    if File.exist?(oauth_config_file)
      puts "config/oauth.json already exists; not overwriting"
    else
      oauth_keys = {
        :iwhd => {
          :consumer_key => random_key,
          :consumer_secret => random_key
        },
        :factory => {
          :consumer_key => random_key,
          :consumer_secret => random_key
        }
      }
      key_file = File.open(oauth_config_file, 'w+')
      key_file.write(oauth_keys.to_json)
    end
  end

  desc "Decrement user's login counter"
  task :decrement_counter, [:username] => :environment do |t, args|
    user = User.find_by_username(args.username)

    unless user
      puts "User '#{args.username}' not found"
      exit(1)
    end

    user.login_count = user.login_count > 1 ? user.login_count - 1 : 0

    if user.save
      puts "Login counter for user #{args.username} updated"
    else
      puts "Failed to update login counter for user #{args.username}: #{user.errors.join(', ')}"
    end

  end

  desc 'Data upgrade for conductor'
  # this should eventually be pulled out into a separate "upgrade everything in here" directory
  task :upgrade => :environment do
    Role.transaction do
      image_admin_role = Role.find_by_name("base.image.admin")
      if image_admin_role and image_admin_role.privileges.
          where(:target_type => "ProviderAccount").empty?
        ["view", "use"].each do |action|
          Privilege.create!(:role => image_admin_role,
                            :target_type => "ProviderAccount",
                            :action => action)
        end
      end
    end
  end

  task :admin_exists => :environment do
    no_admins = BasePermissionObject.general_permission_scope.permissions.includes(:role => :privileges).where("privileges.target_type" => "BasePermissionObject","privileges.action" => Privilege::PERM_SET).empty?
    if no_admins
      exit(1)
    end
  end

  def get_account(provider_name, account_name)
    unless provider = Provider.find_by_name(provider_name)
      raise "There is no provider with '#{provider_name}' name"
    end
    unless account = provider.provider_accounts.find_by_label(account_name)
      raise "There is no account with '#{account_name}' label"
    end
    account
  end

  def random_key(bytes=24)
    SecureRandom.base64(bytes)
  end
end
