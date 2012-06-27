namespace :dc do
  desc 'Create and register a new user'
  task :create_user, [:login, :password, :email, :first_name, :last_name] => :environment do |t, args|
    unless args.login && args.email && args.password
      puts "Usage: rake 'dc:create_user[login,password,email,first_name,last_name]'"
      exit(1)
    end

    user = User.find_by_login(args.login)

    if user
      puts "User already exists: #{args.login}"
      exit(1)
    end

    first_name = args.first_name.nil? ? "" : args.first_name
    last_name  = args.last_name.nil?  ? "" : args.last_name

    user = User.new(:login => args.login, :email => args.email,
                    :password => args.password,
                    :password_confirmation => args.password,
                    :first_name => first_name,
                    :last_name  => last_name,
                    :quota => Quota.new)
    registration = RegistrationService.new(user)
    if registration.save
      puts "User #{args.login} registered"
    else
      puts "User registration failed: #{registration.error}"
    end
  end

  desc 'Destroy an existing user'
  task :destroy_user, [:login] => :environment do |t, args|
    unless args.login
      puts "Usage: rake 'dc:destroy_user[login]'"
      exit(1)
    end

    user = User.find_by_login(args.login)

    if !user
      puts "User not found: #{args.login}"
      exit(1)
    elsif user.destroy
      puts "User #{args.login} destroyed"
    else
      puts "User destruction failed: #{args.login}"
      exit(1)
    end
  end


  desc 'Create and register a list of ldap users, separated by ":"'
  task :create_ldap_users, [:logins] => :environment do |t, args|
    unless args.logins
      puts "Usage: rake 'dc:create_ldap_users[login1:login2:...]'"
      exit(1)
    end

    args.logins.split(":").each do |login|
      user = User.find_by_login(args.login)

      if user
        puts "User already exists: #{login}"
      end

      begin
        user = User.create_ldap_user!(login)
        puts "User #{login} registered"
      rescue Exception => e
        puts "User registration failed: #{e}"
      end
    end
  end


  desc 'Grant administrator privileges to registred user'
  task :site_admin, [:login] => :environment do |t, args|
    unless args.login
      puts "Usage: rake dc:site_admin[user]"
      exit(1)
    end

    user = User.find_by_login(args.login)

    unless user
      puts "Unknown user: #{args.login}"
      exit(1)
    end

    unless user.permissions.select { |p| p.role.name.eql?('base.admin') }.empty?
      puts "Permission already granted for user #{args.login}"
      exit(1)
    end
    permission = Permission.new(:role => Role.find_by_name('base.admin'),
                                :permission_object => BasePermissionObject.general_permission_scope,
                                :entity => user.entity)
    if permission.save
      puts "Granting administrator privileges for #{args.login}..."
    else
      puts "Granting administrator privileges for #{args.login} failed #{permission.errors.to_xml}"
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
  task :decrement_counter, [:login] => :environment do |t, args|
    user = User.find_by_login(args.login)

    unless user
      puts "User '#{args.login}' not found"
      exit(1)
    end

    user.login_count = user.login_count > 1 ? user.login_count - 1 : 0

    if user.save
      puts "Login counter for user #{args.login} updated"
    else
      puts "Failed to update login counter for user #{args.login}: #{user.errors.join(', ')}"
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
