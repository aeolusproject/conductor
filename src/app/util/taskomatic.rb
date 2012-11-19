#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

module Taskomatic

  def self.create_instance!(task, match, config_server, config)
    begin
      task.state = Task::STATE_PENDING
      task.save!

      if config_server and config.present?
        task.instance.add_instance_config!(config_server, config)
      end
      task.instance.provider_account = match.provider_account
      task.instance.create_auth_key unless task.instance.instance_key

      task.instance.instance_hwp = create_instance_hwp(task.instance.hardware_profile, match.hardware_profile)
      dcloud_instance = create_dcloud_instance(task.instance, match)

      handle_dcloud_error(dcloud_instance)

      task.state = Task::STATE_RUNNING
      task.save!
      handle_instance_state(task.instance,dcloud_instance)
      task.instance.save!
    rescue HttpException => ex
      task.failure_code = Task::FAILURE_PROVIDER_CONTACT_FAILED
      handle_create_instance_error(task, ex)
    rescue Exception => ex
      handle_create_instance_error(task, ex)
    ensure
      task.instance.save! if task.instance.changed?
      task.save! if task.changed?
    end
  end

  def self.handle_instance_state(instance, dcloud_instance)
      Rails.logger.info "Task instance create completed with key #{dcloud_instance.id} and state #{dcloud_instance.state}"
      instance.external_key = dcloud_instance.id
      instance.state = dcloud_to_instance_state(dcloud_instance.state)
  end

  def self.do_action(task, action)
    task.time_started = Time.now

    begin
      client = task.instance.provider_account.connect
      dcloud_instance = client.instance(task.instance.external_key)

      task.state = Task::STATE_PENDING
      task.save!

      dcloud_instance.send(action)

      Rails.logger.info("Task instance '#{action}' complete, now in state #{dcloud_instance.state}.")

      # Don't update the instance if we're in the process of destroying it:
      unless action == :destroy!
        task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
        task.instance.save!
      end
      task.state = Task::STATE_FINISHED
    rescue Exception => ex
      task.state = Task::STATE_FAILED
      task.message = ex.message
      task.instance.update_attributes(:last_error => ex.message)

      # For RHEV-M, since we need to start up the instance after the vm has been created
      # we also have to handle create_failed state events separately
      if task.instance.state == Instance::STATE_STOPPED && task.action == InstanceTask::ACTION_START &&
          task.instance.provider_account.provider.provider_type.deltacloud_driver == 'rhevm'
        create_failure_events(task.instance, ex)
        task.instance.update_attributes(:state => Instance::STATE_CREATE_FAILED)
      end
    ensure
      task.save! if Task.exists?(task.id)
    end
  end

  def self.start_instance(task)
    do_action(task, :start!)
  end

  def self.stop_instance(task)
    do_action(task, :stop!)
  end

  def self.reboot_instance(task)
    do_action(task, :reboot!)
  end

  def self.destroy_instance(task)
    do_action(task, :destroy!)
  end

  def self.dcloud_to_instance_state(state_str)
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
    when 'STOPPING'
      return Instance::STATE_SHUTTING_DOWN
    else
      return Instance::STATE_PENDING
    end
  end

  private

  class HttpException < Exception
  end

  def self.handle_dcloud_error(dcloud_instance)
    raise HttpException, "Error creating dcloud instance, returned internal server error." if dcloud_instance.class == Net::HTTPInternalServerError
  end

  def self.handle_create_instance_error(task, ex)
    log_backtrace(ex)
    task.state = Task::STATE_FAILED
    task.instance.state = Instance::STATE_CREATE_FAILED
    create_failure_events(task.instance, ex)

    raise ex
  end

  def self.create_instance_hwp(frontend_hardware_profile, backend_hardware_profile)
    overrides = HardwareProfile.generate_override_property_values(frontend_hardware_profile, backend_hardware_profile)
    ihwp = InstanceHwp.new(overrides)
    ihwp.hardware_profile = backend_hardware_profile
    ihwp.save!
    ihwp
  end

  def self.create_dcloud_instance(instance, match)
    client = match.provider_account.connect
    raise _("Could not connect to Provider Account.  Please contact an Administrator.") unless client

    client_args = {
      :image_id    => match.provider_image,
      :hwp_id      => match.hardware_profile.external_key,
      :name        => instance.name.tr("/", "-"),
      :hwp_memory  => instance.instance_hwp.memory,
      :hwp_cpu     => instance.instance_hwp.cpu,
      :hwp_storage => instance.instance_hwp.storage,
      :keyname     => (instance.instance_key.name rescue nil)
    }
    client_args.merge!({:realm_id => match.realm.external_key}) if (match.realm.external_key.present? rescue false)
    client_args.merge!({:user_data => instance.user_data}) if instance.user_data.present?
    client.create_instance(client_args)
  end

  def self.create_failure_events(instance, ex)
    instance.events << Event.create(
      :source => instance,
      :event_time => DateTime.now,
      :status_code => 'instance_launch_failed',
      :summary => "#{instance.name}: #{ex.message.to_s.split("\n").first}"
    )

    instance.provider_account.events << Event.create(
      :source => instance.provider_account,
      :event_time => DateTime.now,
      :status_code => 'provider_account_failure',
      :summary => "#{instance.name}: #{ex.message.to_s.split("\n").first}"
    )
  end
end
