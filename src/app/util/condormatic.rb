#
# Copyright (C) 2010,2011 Red Hat, Inc.
#  Written by Ian Main <imain@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

require 'fileutils'
require 'tempfile'

class Possible
  attr_reader :pool_family, :account, :hwp, :provider_image, :realm

  def initialize(pool_family, account, hwp, provider_image, realm)
    @pool_family = pool_family
    @account = account
    @hwp = hwp
    @provider_image = provider_image
    @realm = realm
  end
end

def match(instance)
  possibles = []

  template_id = instance.template ? instance.template.id : instance.assembly.templates.first.id

  PoolFamily.all.each do |pool_family|
    if instance.pool.pool_family.id != pool_family.id
      next
    end

    pool_family.provider_accounts.each do |account|
      # match_provider_hardware_profile returns a single provider
      # hardware_profile that can satisfy the input hardware_profile
      hwp = HardwareProfile.match_provider_hardware_profile(account.provider,
                                                            instance.hardware_profile)

      provider_images = hwp.provider.legacy_provider_images.find(:all,
                                                          :conditions => ['provider_image_key IS NOT NULL'])
      provider_images.each do |pi|
        if pi.image.template.id != template_id
          next
        end

        if not instance.frontend_realm.nil?
          instance.frontend_realm.realm_backend_targets.each do |brealm|
            possibles << Possible.new(pool_family, account, hwp, pi,
                                      brealm.realm)
          end
        else
          possibles << Possible.new(pool_family, account, hwp, pi, nil)
        end
      end
    end
  end

  possibles.each do |match|
    # FIXME: we should have something smarter here that prioritizes
    # and/or chooses the "cheapest" possibility.  For now, just return the
    # first that fits under quota
    if Quota.can_create_instance?(instance, match.account)
      return match
    end
  end

  return nil
end

def pipe_and_log(pipe, instr)
  pipe.puts instr
  Rails.logger.error instr
end

def write_pw_file(job_name, pw)
  # here we write out the password file
  # FIXME: should this be configurable?
  pwdir = '/var/lib/aeolus-conductor/jobs'
  FileUtils.mkdir_p(pwdir, options={:mode => 0700})
  FileUtils.chown('aeolus', 'aeolus', pwdir)

  pwfilename = File.join(pwdir, job_name)

  tmpfile = Tempfile.new(job_name, pwdir)
  tmpfilename = tmpfile.path
  tmpfile.write(pw)
  tmpfile.close

  File.rename(tmpfilename, pwfilename)

  return pwfilename
end

def condormatic_instance_create(task)
  instance = task.instance
  found = match(instance)

  begin
    if found.nil?
      Rails.logger.error "Couldn't find a match!"
      raise ("Could not find a matching backend provider")
    end

    job_name = "job_#{instance.name}_#{instance.id}"

    instance.condor_job_id = job_name

    overrides = HardwareProfile.generate_override_property_values(instance.hardware_profile,
                                                                  found.hwp)
    keyname = found.account.instance_key ? found.account.instance_key.name : ''

    pwfilename = write_pw_file(job_name,
                               found.account.credentials_hash['password'])

    # I use the 2>&1 to get stderr and stdout together because popen3 does not
    # support the ability to get the exit value of the command in ruby 1.8.
    pipe = IO.popen("condor_submit 2>&1", "w+")
    pipe_and_log(pipe, "universe = grid\n")
    pipe_and_log(pipe, "executable = #{job_name}\n")

    pipe_and_log(pipe,
                 "grid_resource = deltacloud #{found.account.provider.url}\n")
    pipe_and_log(pipe, "DeltacloudUsername = #{found.account.credentials_hash['username']}\n")
    pipe_and_log(pipe, "DeltacloudPasswordFile = #{pwfilename}")
    pipe_and_log(pipe, "DeltacloudImageId = #{found.provider_image.provider_image_key}\n")
    pipe_and_log(pipe,
                 "DeltacloudHardwareProfile = #{found.hwp.external_key}\n")
    pipe_and_log(pipe,
                 "DeltacloudHardwareProfileMemory = #{overrides[:memory]}\n")
    pipe_and_log(pipe,
                 "DeltacloudHardwareProfileCPU = #{overrides[:cpu]}\n")
    pipe_and_log(pipe,
                 "DeltacloudHardwareProfileStorage = #{overrides[:storage]}\n")
    pipe_and_log(pipe, "DeltacloudKeyname = #{keyname}\n")
    pipe_and_log(pipe, "DeltacloudPoolFamily = #{found.pool_family.id}\n")

    if found.realm != nil
      pipe_and_log(pipe, "DeltacloudRealmId = #{found.realm.external_key}\n")
    end

    pipe_and_log(pipe, "requirements = true\n")
    pipe_and_log(pipe, "notification = never\n")
    pipe_and_log(pipe, "queue\n")

    pipe.close_write
    out = pipe.read
    pipe.close

    Rails.logger.error "$? (return value?) is #{$?}"
    raise ("Error calling condor_submit: #{out}") if $? != 0

  rescue Exception => ex
    Rails.logger.error ex.message
    Rails.logger.error ex.backtrace
    task.state = Task::STATE_FAILED
    instance.state = Instance::STATE_CREATE_FAILED
  else
    task.state = Task::STATE_PENDING
  end
  instance.save!
  task.save!
end

def condormatic_instance_stop(task)
    instance =  task.instance_of?(InstanceTask) ? task.instance : task

    Rails.logger.info("calling condor_rm -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    pipe = IO.popen("condor_rm -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    out = pipe.read
    pipe.close

    Rails.logger.info("condor_rm return status is #{$?}")
    Rails.logger.error("Error calling condor_rm (exit code #{$?}) on job: #{out}") if $? != 0
end

def condormatic_instance_reset_error(instance)

  condormatic_instance_stop(instance)
    Rails.logger.info("calling condor_rm -forcex -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    pipe = IO.popen("condor_rm -forcex -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    out = pipe.read
    pipe.close

    Rails.logger.info("condor_rm return status is #{$?}")
    Rails.logger.error("Error calling condor_rm (exit code #{$?}) on job: #{out}") if $? != 0
end

def condormatic_instance_destroy(task)
    instance = task.instance

    Rails.logger.info("calling condor_rm -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    pipe = IO.popen("condor_rm -constraint 'Cmd == \"#{instance.condor_job_id}\"' 2>&1")
    out = pipe.read
    pipe.close

    Rails.logger.info("condor_rm return status is #{$?}")
    Rails.logger.error("Error calling condor_rm (exit code #{$?}) on job: #{out}") if $? != 0
end
