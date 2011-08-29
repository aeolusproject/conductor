#
# Copyright (C) 2011 Red Hat, Inc.
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

module Taskomatic

  def self.create_instance(task)
    begin
      match = matches(task.instance).first

      task.state = Task::STATE_PENDING
      task.save!

      task.instance.provider_account = match.provider_account
      task.instance.create_auth_key unless task.instance.instance_key

      dcloud_instance = create_dcloud_instance(task.instance, match)

      handle_dcloud_error(dcloud_instance)

      task.state = Task::STATE_RUNNING
      task.save!

      Rails.logger.info "Task instance create completed with key #{dcloud_instance.id} and state #{dcloud_instance.state}"
      task.instance.external_key = dcloud_instance.id
      task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
      task.instance.save!
    rescue HttpException => ex
      task.failure_code = Task::FAILURE_PROVIDER_CONTACT_FAILED
      handle_create_instance_error(task, ex)
    rescue Exception => ex
      handle_create_instance_error(task, ex)
    ensure
      task.instance.save!
      task.save!
    end
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

      task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
      task.instance.save!
      task.state = Task::STATE_FINISHED
    rescue Exception => ex
      task.state = Task::STATE_FAILED
      task.message = ex.message
    ensure
      task.save!
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
    task.time_started = Time.now

    begin
      client = task.instance.provider_account.connect
      dcloud_instance = client.instance(task.instance.external_key)

      task.state = Task::STATE_PENDING
      task.save!

      dcloud_instance.destroy!

      Rails.logger.info("Task Destroy completed.")

      task.state = Task::STATE_FINISHED
    rescue Exception => ex
      task.state = Task::STATE_FAILED
      task.message = ex.message
    ensure
      task.save!
    end
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
    Rails.logger.error ex.message
    Rails.logger.error ex.backtrace.join("\n")
    task.state = Task::STATE_FAILED
    task.instance.state = Instance::STATE_CREATE_FAILED
    raise ex
  end

  def self.create_dcloud_instance(instance, match)
    client = match.provider_account.connect

    overrides = HardwareProfile.generate_override_property_values(instance.hardware_profile, match.hwp)

    client.create_instance(:image_id => match.provider_image.target_identifier,
                           :name => instance.name.tr("/", "-"),
                           :hwp_id => match.hwp.external_key,
                           :hwp_memory => overrides[:memory],
                           :hwp_cpu => overrides[:cpu],
                           :hwp_storage => overrides[:storage],
                           :realm_id => (match.realm.external_key rescue nil),
                           :keyname => (instance.instance_key.name))
  end

  def self.matches(instance)
    matched, errors = instance.matches
    if matched.empty?
      raise "Could not find a matching backend provider, errors: #{errors.join(', ')}"
    end
    matched
  end

end
