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

    user.permissions << Permission.new(:role => Role.find_by_name('Administrator'),
                                       :permission_object => BasePermissionObject.general_permission_scope)
    puts "Granting administrator privileges for #{args.login}..."
  end


  desc 'Download and parse repository xml files'
  task :prepare_repos => :environment do |t, args|
    require 'util/repository_manager'
    RepositoryManager.new.repositories.each { |repo| repo.prepare_repo if repo.type == 'xml' }
  end

  desc 'Create user "admin" for CloudEngine'
  task :create_admin_user => :environment do
    Rake::Task[:'dc:create_user'].invoke('admin', 'password', 'admin@deltacloud.org', 'Administrator', 'Administrator')
    Rake::Task[:'dc:site_admin'].invoke('admin')
  end


  desc 'Setup CloudEngine and create admin user automatically'
  task :setup => :environment do
    print "Reset database to clean state (YES/no)? "
    STDOUT.flush
    drop_db = STDIN.gets.chomp
    unless drop_db.strip.eql?('no')
      Rake::Task[:'db:drop'].invoke
      Rake::Task[:'db:create'].invoke
      Rake::Task[:'db:migrate'].invoke
    end
    Rake::Task[:'dc:create_admin_user'].invoke
  end

end
