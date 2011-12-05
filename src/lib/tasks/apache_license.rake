# rake license:verify
# If defined the environment variable with the command like:
#   rake license:verify list=<all>
# list is set with values:
#  - all: list all the files
#  - gpl: list the files with gpl license
#  - gpl_nor_asl: list of files without licenses
#  - apache: list of files with apache license

namespace :license do
  desc 'Operations to verify status of licenses on files'

  task :verify  do |t, args|
    gpl=%x[find ./ -type f -iname '*.rb' -exec grep -qE "http://www.gnu.org/copyleft/gpl.html" {} \\; -print].split
    gpl_nor_asl=%x[find ./ -type f -iname '*.rb' \\! -exec grep -qE "http://www.gnu.org/copyleft/gpl.html" {} \\; -print].split
    apache=%x[find ./ -type f -iname '*.rb' -exec grep -qE "Apache License" {} \\; -print].split
    if (!ENV["list"] or ENV["list"].empty?)
      puts "Files that contain GPL License: %d" % (gpl.size)
      puts "Files that have neither GPL nor ASL: %d" % (gpl_nor_asl.size)
      puts "Files that contain Apache license: %d" % (apache.size)
    else
     puts "Files that contain GPL License:"<<gpl.join(', ') if ENV["list"].include?("gpl") or ENV["list"]=="all"
     puts "Files that have neither GPL nor ASL:" << gpl_nor_asl.join(', ') if ENV["list"].include?("gpl_nor_asl") or ENV["list"]=="all"
     puts "Files that contain Apache license: " << apache.join(', ') if ENV["list"].include?("apache") or ENV["list"]=="all"
    end
  end

  #namespace end
end
