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

  QuotaResource = Struct.new(:name, :used, :max, :available, :unit)

  NO_LIMIT = nil

  has_one :pool
  has_one :cloud_account

  def can_create_instance?(instance)
    hwp = instance.hardware_profile

    potential_total_storage = total_storage.to_f + hwp.storage.value.to_f
    potential_total_instances = total_instances + 1

    # check for no quota
    if (Quota.no_limit(maximum_total_instances) || maximum_total_instances >= potential_total_instances) &&
       (Quota.no_limit(maximum_total_storage) || maximum_total_storage.to_f >= potential_total_storage.to_f)
         return true
    end
    return false
  end

  def can_start_instance?(instance)
    hwp = instance.hardware_profile

    potential_running_instances = running_instances + 1
    potential_running_memory = running_memory.to_f + hwp.memory.value.to_f
    potential_running_cpus = running_cpus.to_f + hwp.cpu.value.to_f

    if (Quota.no_limit(maximum_running_instances) || maximum_running_instances >= potential_running_instances) &&
       (Quota.no_limit(maximum_running_memory) || maximum_running_memory.to_f >= potential_running_memory) &&
       (Quota.no_limit(maximum_running_cpus) || maximum_running_cpus.to_f >= potential_running_cpus)
         return true
    end
    return false
  end

  def quota_resources()
    quota_resources =  {"running_instances" => QuotaResource.new("Running Instances", running_instances, maximum_running_instances, maximum_running_instances.to_f - running_instances.to_f, ""),
            "running_memory" => QuotaResource.new("Running Memory", running_memory, maximum_running_memory, maximum_running_memory.to_f - running_memory.to_f, "MB"),
            "running_cpus" => QuotaResource.new("Running CPUs", running_cpus, maximum_running_cpus, maximum_running_cpus.to_f - running_cpus.to_f, ""),
            "total_instances" => QuotaResource.new("Total Instances", total_instances, maximum_total_instances, maximum_total_instances.to_f - total_instances.to_f, ""),
            "total_storage" => QuotaResource.new("Total Storage", total_storage, maximum_total_storage, maximum_total_storage.to_f - total_storage.to_f, "GB")}

    quota_resources.each_value do |quota_resource|
      if Quota.no_limit(quota_resource.max)
        quota_resource.max = "No Limit"
        quota_resource.available = "N\A"
      end
    end

    return quota_resources
  end

  def self.no_limit(resource)
    if resource.to_s == NO_LIMIT.to_s
      return true
    end
    return false
  end

end
