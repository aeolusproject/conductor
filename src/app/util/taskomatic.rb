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

    @task.time_started = Time.now

    begin
      client = @task.instance.cloud_account.connect
      realm = @task.instance.realm.external_key rescue nil
      dcloud_instance = client.create_instance(@task.instance.image.external_key,
                                               :flavor => @task.instance.hardware_profile.external_key,
                                               :realm => realm,
                                               :name => @task.instance.name)
      if dcloud_instance.class == Net::HTTPInternalServerError
        @task.instance.state = Instance::STATE_CREATE_FAILED
        raise "Error creating dcloud instance, returned internal server error."
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
    @task.time_ended = Time.now
    @task.save!
  end

  def do_action(action)
    @task.time_started = Time.now

    begin
      client = @task.instance.cloud_account.connect
      dcloud_instance = client.instance(@task.instance.external_key)
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
    @task.time_ended = Time.now
    @task.save!
  end

  def instance_start
    do_action(:start!)
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

      dcloud_instance.destroy!

      @logger.info("Task Destroy completed.")
    rescue Exception => ex
      @task.state = Task::STATE_FAILED
      @task.message = ex.message
    else
      @task.state = Task::STATE_FINISHED
    end
    @task.time_ended = Time.now
    @task.save!
  end
end

