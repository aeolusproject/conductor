# Copyright (C) 2009 Red Hat, Inc.
# Written by Ian Main <imain@redhat.com>
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

require 'taskomatic_task'

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

# Create a new instance on a cloud.
class TaskomaticInstanceCreate < TaskomaticTask

  def initialize(logger, task)
    super(logger, task)
    @logger.info("TaskomaticInstanceCreate created.")
  end

  def run
    @logger.info("TaskomaticInstanceCreate running.")

    client = @task.instance.portal_pool.cloud_account.connect
    puts "client is #{client.type}"
    @logger.info "Creating instance with name #{@task.instance.image.external_key}, flavor #{@task.instance.flavor.external_key}, realm #{@task.instance.realm.external_key}, name #{@task.instance.name}"
    dcloud_instance = client.create_instance(@task.instance.image.external_key,
                                             :flavor => @task.instance.flavor.external_key,
                                             :realm => @task.instance.realm.external_key,
                                             :name => @task.instance.name)
    if dcloud_instance.class == Net::HTTPInternalServerError
      @task.instance.state = Instance::STATE_CREATE_FAILED
      raise "Error creating dcloud instance, returned internal server error."
    end

    @logger.info "Instance created with key #{dcloud_instance.id} and state #{dcloud_instance.state}"
    @task.instance.external_key = dcloud_instance.id
    @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
    @task.instance.save!

    while dcloud_instance.state.upcase == 'PENDING'
      sleep(3)
      dcloud_instance = client.instance(@task.instance.external_key)
    end

    @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
    @task.instance.save!

    # Instance::STATE_NEW
    # Instance::STATE_PENDING
    # Instance::STATE_RUNNING
    # Instance::STATE_SHUTTING_DOWN
    # Instance::STATE_STOPPED

    @logger.info("New instance created.")
  end
end

# Start a stopped instance on a cloud
class TaskomaticInstanceStart < TaskomaticTask

  def initialize(logger, task)
    super(logger, task)
    @logger.info("TaskomaticInstanceStart created.")
  end

  def run
    @logger.info("TaskomaticInstanceStart running.")

    client = @task.instance.portal_pool.cloud_account.connect
    dcloud_instance = client.instance(@task.instance.external_key)
    dcloud_instance.start!

    @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
    @task.instance.save!

    @logger.info("Command completed, instance now in state #{dcloud_instance.state}")
    while dcloud_instance.state.upcase == 'PENDING'
      sleep(3)
      dcloud_instance = client.instance(@task.instance.external_key)
    end
    @logger.info("After wait, instance now in state #{dcloud_instance.state}")

    @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
    @task.instance.save!

    @logger.info("Instance started.")
  end
end

# Stop an instance.
class TaskomaticInstanceStop < TaskomaticTask

  def initialize(logger, task)
    super(logger, task)
    @logger.info("TaskomaticInstanceStop started.")
  end

  def run
    @logger.info("TaskomaticInstanceStop running.")

    client = @task.instance.portal_pool.cloud_account.connect
    dcloud_instance = client.instance(@task.instance.external_key)
    dcloud_instance.stop!

    @logger.info("Command completed, instance now in state #{dcloud_instance.state}")
    @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
    @task.instance.save!

    while dcloud_instance.state.upcase == 'PENDING' or dcloud_instance.state.upcase == "SHUTTING_DOWN"
      sleep(3)
      dcloud_instance = client.instance(@task.instance.external_key)
    end

    @logger.info("After wait, instance now in state #{dcloud_instance.state}")
    @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
    @task.instance.save!

    @logger.info("Instance stopped.")
  end
end

# Reboot an instance.
class TaskomaticInstanceReboot < TaskomaticTask

  def initialize(logger, task)
    super(logger, task)
    @logger.info("TaskomaticInstanceReboot started.")
  end

  def run
    @logger.info("TaskomaticInstanceReboot running.")

    client = @task.instance.portal_pool.cloud_account.connect
    dcloud_instance = client.instance(@task.instance.external_key)
    dcloud_instance.reboot!

    @logger.info("Command completed, instance now in state #{dcloud_instance.state}")
    @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
    @task.instance.save!

    while dcloud_instance.state.upcase == 'PENDING' or dcloud_instance.state.upcase == "SHUTTING_DOWN"
      sleep(3)
      dcloud_instance = client.instance(@task.instance.external_key)
    end

    @logger.info("After wait, instance now in state #{dcloud_instance.state}")
    @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
    @task.instance.save!

    @logger.info("Reboot completed.")
  end
end

# Destroy an instance.
class TaskomaticInstanceDestroy < TaskomaticTask

  def initialize(logger, task)
    super(logger, task)
    @logger.info("TaskomaticInstanceDestroy started.")
  end

  def run
    @logger.info("TaskomaticInstanceDestroy running.")

    client = @task.instance.portal_pool.cloud_account.connect
    dcloud_instance = client.instance(@task.instance.external_key)
    dcloud_instance.destroy!

    @logger.info("Command completed, instance now in state #{dcloud_instance.state}")
    @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
    @task.instance.save!

    while dcloud_instance.state.upcase == 'PENDING' or dcloud_instance.state.upcase == "SHUTTING_DOWN"
      sleep(3)
      dcloud_instance = client.instance(@task.instance.external_key)
    end

    @logger.info("After wait, instance now in state #{dcloud_instance.state}")
    @task.instance.state = dcloud_to_instance_state(dcloud_instance.state)
    @task.instance.save!

    @logger.info("Destroy completed.")
  end
end
