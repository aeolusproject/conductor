namespace :dc do
  desc 'Create and register a new user'
  task :create_user, [:login, :password, :email, :first_name, :last_name] => :environment do |t, args|
    unless args.login && args.email && args.password && args.first_name && args.last_name
      puts "Usage: rake 'dc:create_user[login,password,email,first_name,last_name]'"
      exit(1)
    end

    user = User.find_by_login(args.login)

    if user
      puts "User already exists: #{args.login}"
      exit(1)
    end

    user = User.new(:login => args.login, :email => args.email,
                    :password => args.password,
                    :password_confirmation => args.password,
                    :first_name => args.first_name,
                    :last_name => args.last_name,
                    :quota => Quota.new)
    registration = RegistrationService.new(user)
    if registration.save
      puts "User #{args.login} registered"
    else
      puts "User registration failed: #{registration.error}"
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

    unless user.permissions.select { |p| p.role.name.eql?('Administrator') }.empty?
      puts "Permission already granted for user #{args.login}"
      exit(1)
    end
    permission = Permission.new(:role => Role.find_by_name('Administrator'),
                                :permission_object => BasePermissionObject.general_permission_scope,
                                :user => user)
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
