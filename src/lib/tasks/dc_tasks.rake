namespace :dc do
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
