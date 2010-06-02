#
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Quota < ActiveRecord::Base
  has_one :pool
  has_one :cloud_account

  validates_presence_of :maximum_running_instances
  validates_presence_of :maximum_running_memory
  validates_presence_of :maximum_running_cpus

  validates_presence_of :maximum_total_storage
  validates_presence_of :maximum_total_instances

  validates_numericality_of :maximum_running_instances
  validates_numericality_of :maximum_running_memory
  validates_numericality_of :maximum_running_cpus

  validates_numericality_of :maximum_total_storage
  validates_numericality_of :maximum_total_instances


  def can_create_instance?(instance)
    # TODO Fix: When this returns failed, instance gets deleted at some point from database.  It should be kept for audit
    hwp = instance.hardware_profile

    potential_total_storage = total_storage.to_f + hwp.storage.value.to_f
    potential_total_instances = total_instances + 1

    if maximum_total_instances >= potential_total_instances && maximum_total_storage.to_f >= potential_total_storage.to_f
      return true
    end
    return false
  end

  def can_start_instance?(instance)
    hwp = instance.hardware_profile

    potential_running_instances = running_instances + 1
    potential_running_memory = running_memory.to_f + hwp.memory.value.to_f
    potential_running_cpus = running_cpus.to_f + hwp.cpu.value.to_f

    if maximum_running_instances >= potential_running_instances && maximum_running_memory.to_f >= potential_running_memory && maximum_running_cpus.to_f >= potential_running_cpus
      return true
    end
    return false
  end

  def validate
    errors.add("maximum_running_instances", "cannot be less than the current running instances") if maximum_running_instances < running_instances
    errors.add("maximum_running_memory", "cannot be less than the current running memory") if maximum_running_memory.to_f < running_memory.to_f
    errors.add("maximum_running_cpus", "cannot be less than the current running CPUs") if maximum_running_cpus.to_f < running_cpus.to_f
    errors.add("maximum_total_storage", "cannot be less than the current total storage") if maximum_total_storage.to_f < total_storage.to_f
    errors.add("maximum_total_instances", "cannot be less than the current total instances") if maximum_total_instances < total_instances
  end
end
