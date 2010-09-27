require 'rubygems'
require 'active_record'
require 'search_filter'
require 'permissioned_object'
require 'authlogic'
require 'user'
require 'instance'
require 'cloud_account'
require 'pool'
require 'quota'
require 'parseconfig'

def classad_plugin(logf, conf_path, instance_key, account_id)
  rails_env = "development"
  begin
    config = ParseConfig.new('/etc/sysconfig/deltacloud-rails')
    env = config.get_value("RAILS_ENV")
    if not env.nil?
      rails_env = env
    end
  rescue
    # if any of this failed, then just assume the development database and
    # hope for the best
  end

  logf.puts "loading db config from #{conf_path}"
  conf = YAML::load(File.open(conf_path))
  ActiveRecord::Base.establish_connection(conf[rails_env])

  # I left the puts in here because you can run condor_negotiator -f from the
  # command line and it will print this stuff out.  Very nice for debugging.
  logf.puts "getting instance from key #{instance_key}"
  instance = Instance.find(:first,
                           :conditions => [ "condor_job_id = ?", instance_key ])
  logf.puts "getting cloud account from id #{account_id}"
  cloud_account = CloudAccount.find(:first,
                                    :conditions => [ "id = ?", account_id ])

  logf.puts "instance is: #{instance}, cloud account is #{cloud_account}"

  return false if instance.nil?
  return false if cloud_account.nil?

  logf.puts "checking quota.."
  ret = Quota.can_start_instance?(instance, cloud_account)

  ActiveRecord::Base.connection.disconnect!

  return ret
end
