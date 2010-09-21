
require 'dutils'

def classad_plugin(instance_key, account_id)

    # I left the puts in here because you can run condor_negotiator -f from the command
    # line and it will print this stuff out.  Very nice for debugging.
    puts "getting instance from key #{instance_key}"
    instance = Instance.find(:first, :conditions => [ "condor_job_id = ?", instance_key ])
    puts "getting cloud account from id #{account_id}"
    cloud_account = CloudAccount.find(:first, :conditions => [ "id = ?", account_id ])

    puts "instance is: #{instance}, cloud account is #{cloud_account}"

    return false if instance.nil?
    return false if cloud_account.nil?
    puts "checking quota.."
    return Quota.can_start_instance?(instance, cloud_account)
end
