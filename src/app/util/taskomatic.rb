 #
# Copyright (C) 2010 Red Hat, Inc.
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


def dcloud_to_instance_state(state_str)
  case state_str.upcase
    when 'PENDING'
      return Instance::STATE_PENDING
    when 'RUNNING'
      return Instance::STATE_RUNNING
    when 'STOPPED'
      return Instance::STATE_STOPPED
    when 'TERMINATED'
      return Instance::STATE_STOPPED
    when 'SHUTTING_DOWN'
      return Instance::STATE_SHUTTING_DOWN
  else
    return Instance::STATE_PENDING
  end
end


class Taskomatic

  def initialize(task, logger)
    @task = task
    @logger = logger
  end

  def instance_create

    # This block assumes that all providers will put instance into running state after create,
    # Therefore this block checks both whether the instance can be created and whether the instance
    # can go to state running.
    # TODO Modify this to handle generic case for providers
    pool = @task.instance.pool

    #find matching cloud account
    if @task.instance.cloud_account
      cloud_accounts = [@task.instance.cloud_account]
    else
      # FIXME: this provides a predictable order -- scheduler will eventually
      # do something entirely different to determine preference
      cloud_accounts = CloudAccount.find(:all, :order => 'created_at')
    end

    if @task.instance.image.provider_image?
      image_providers = Set.new([@task.instance.image])
    else
      image_providers = Set.new(@task.instance.image.provider_images.
                                 collect { |image| image.provider})
    end

    if @task.instance.hardware_profile.provider_hardware_profile?
      hwp_providers = Set.new([@task.instance.hardware_profile])
    else
      hwp_providers = Set.new(@task.instance.hardware_profile.provider_hardware_profiles.
                              collect { |hwp| hwp.provider })
    end

    matching_providers = hwp_providers & image_providers
    cloud_accounts.delete_if do |acct|
      !matching_providers.include?(acct.provider) or
        (acct.quota and
         (!acct.quota.can_create_instance?(@task.instance) or
          !acct.quota.can_start_instance?(@task.instance)))
    end

    if pool.quota and
        (!pool.quota.can_create_instance?(@task.instance) or
         !pool.quota.can_start_instance?(@task.instance))
      @task.failure_code =  Task::FAILURE_OVER_POOL_QUOTA
    end
    @task.failure_code = Task::FAILURE_PROVIDER_NOT_FOUND if cloud_accounts.empty?

    unless @task.failure_code.nil?
      @task.state = Task::STATE_FAILED
      @task.instance.state = Instance::STATE_CREATE_FAILED
      @task.save!
      @task.instance.save!
      return @task
    end

    begin
      # take first matching cloud account
      @task.instance.cloud_account = cloud_accounts[0]
      client = @task.instance.cloud_account.connect
      realm = @task.instance.realm.external_key rescue nil

      # Map aggregator HWP/image to back-end provider HWP/image in instance
      unless @task.instance.image.provider_image?
        @task.instance.image = @task.instance.image.provider_images.
          find(:first, :conditions => {:provider_id =>
                 @task.instance.cloud_account.provider_id})
      end

      unless @task.instance.hardware_profile.provider_hardware_profile?
        @task.instance.hardware_profile = @task.instance.hardware_profile.
          provider_hardware_profiles.
          find(:first, :conditions => {:provider_id =>
                 @task.instance.cloud_account.provider_id})
      end

      @task.state = Task::STATE_PENDING
      @task.save!
      dcloud_instance = client.create_instance(@task.instance.image.external_key,
                                               :flavor => @task.instance.hardware_profile.external_key,
                                               :realm => realm,
                                               :name => @task.instance.name)
      if dcloud_instance.class == Net::HTTPInternalServerError
        @task.instance.state = Instance::STATE_CREATE_FAILED
        raise "Error creating dcloud instance, returned internal server error."
        @task.state = TASK::STATE_FAILED
        @task.failure_code = Task::FAILURE_PROVIDER_CONTACT_FAILED
      else
        @task.state = Task::STATE_RUNNING
        @task.save!
      end

      @logger.info "Task instance create completed with key #{dcloud_instance.id} and state #{dcloud_instance.state}"
      @task.instance.external_key = dcloud_instance.id
      @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
      @task.instance.save!
    rescue Exception => ex
      @task.state = Task::STATE_FAILED
      @task.message = ex.message
    else
      @task.state = Task::STATE_FINISHED
    end

    @task.save!
  end

  def do_action(action)
    @task.time_started = Time.now

    begin
      client = @task.instance.cloud_account.connect
      dcloud_instance = client.instance(@task.instance.external_key)

      @task.state = Task::STATE_PENDING
      @task.save!
      dcloud_instance.send(action)

      @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
      @task.instance.save!
      @logger.info("Task instance '#{action}' complete, now in state #{dcloud_instance.state}.")
    rescue Exception => ex
      @task.state = Task::STATE_FAILED
      @task.message = ex.message
    else
      @task.state = Task::STATE_FINISHED
    end
    @task.save!
  end

  def instance_start
    pool = @task.instance.pool
    cloud_account = @task.instance.cloud_account

    [pool, cloud_account].each do |parent|
      quota = parent.quota
      if quota
        if quota.can_start_instance?(@task.instance)
          do_action(:start!)
        else
          @task.state = Task::STATE_FAILED
          if parent.class == Pool
            @task.failure_code =  Task::FAILURE_OVER_POOL_QUOTA
          elsif parent.class == CloudAccount
            @task.failure_code =  Task::FAILURE_OVER_CLOUD_ACCOUNT_QUOTA
          end
          @task.save!
        end
      end
    end
  end

  def instance_stop
    do_action(:stop!)
  end

  def instance_reboot
    do_action(:reboot!)
  end

  def instance_destroy
    @task.time_started = Time.now

    begin
      client = @task.instance.cloud_account.connect
      dcloud_instance = client.instance(@task.instance.external_key)

      @task.state = Task::STATE_PENDING
      @task.save!
      dcloud_instance.destroy!

      @logger.info("Task Destroy completed.")
    rescue Exception => ex
      @task.state = Task::STATE_FAILED
      @task.message = ex.message
    else
      @task.state = Task::STATE_FINISHED
    end
    @task.save!
  end

  # FIXME: this should probably eventually enforce a max refresh rate to prevent
  # too many refreshes  causing scalability problems. In addition this will need
  # to be handled by the scheduler
  def pool_refresh(pool)
    account_clients = {}
    pool.instances.each do |instance|
      if instance.cloud_account and instance.state != Instance::STATE_NEW
        account_clients[instance.cloud_account_id] ||= instance.cloud_account.connect
        api_instance = account_clients[instance.cloud_account_id].instance(instance.external_key)
        if api_instance
          @logger.debug("updating instance state for #{instance.name}: #{instance.external_key}. #{api_instance}")
          instance.state = dcloud_to_instance_state(api_instance.state)
          instance.save!
        else
          instance.destroy
        end
      end
    end
  end

end
