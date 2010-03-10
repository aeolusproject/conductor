namespace :grant do
  desc 'Grant admin privileges to user'
  task :admin_privileges, [:login] => :environment do |t, args|

    unless args.login
      puts "Usage: rake grant:admin_privileges[<user>]"
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
                                       :permission_object => BasePortalObject.general_permission_scope
                                      )
    puts "Granting administrator privileges for #{args.login}..."
  end
end
