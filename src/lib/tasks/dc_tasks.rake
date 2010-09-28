namespace :dc do
  desc 'Create and register a new user'
  task :create_user, [:login] => :environment do |t, args|
    unless args.login && args.email && args.password
      puts "Usage: rake dc:create_user[user] email=abc@xyz password=S3cR3t"
      exit(1)
    end

    user = User.find_by_login(args.login)

    if user
      puts "User already exists: #{args.login}"
      exit(1)
    end

    user = User.new(:login => args.login, :email => args.email,
                    :password => args.password,
                    :password_confirmation => args.password)
    registration = RegistrationService.new(user)
    if registration.save
      puts "User registered"
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
                                       :permission_object => BasePermissionObject.general_permission_scope
                                      )
    puts "Granting administrator privileges for #{args.login}..."
  end


  desc 'Download repository xml files'
  task :download_repos => :environment do |t, args|
    require 'util/repository_manager'

    base_dir = "#{RAILS_ROOT}/config/image_descriptor_xmls"
    Dir.mkdir(base_dir) unless File.directory?(base_dir)

    mgr = RepositoryManager.new
    mgr.repositories.keys.each do |repid|
      rep = mgr.get_repository(repid)

      %w(repomd primary group).each do |type|
        path = "#{base_dir}/#{repid}.#{type}.xml"
        puts "Downloading #{type} file for #{repid} repository -> #{path}"
        File.open(path , "w") { |f| f.write rep.download_xml(type) }
      end
    end
  end

end
