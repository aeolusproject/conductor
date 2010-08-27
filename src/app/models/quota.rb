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

  QuotaResource = Struct.new(:name, :used, :max, :available, :unit)

  NO_LIMIT = nil

  RESOURCE_RUNNING_INSTANCES = "running_instances"
  RESOURCE_TOTAL_INSTANCES = "total_instances"
  RESOURCE_OVERALL = "overall"

  RESOURCE_NAMES = [ RESOURCE_RUNNING_INSTANCES, RESOURCE_TOTAL_INSTANCES ]

  def can_create_instance?(instance)
    potential_total_instances = total_instances + 1
    if (Quota.no_limit(maximum_total_instances) || maximum_total_instances >= potential_total_instances)
         return true
    end
    return false
  end

  def can_start_instance?(instance)
    potential_running_instances = running_instances + 1
    if (Quota.no_limit(maximum_running_instances) || maximum_running_instances >= potential_running_instances)
         return true
    end
    return false
  end

  def quota_resources()
    quota_resources =  {"running_instances" => QuotaResource.new("Running Instances", running_instances, maximum_running_instances, nil, ""),
            "total_instances" => QuotaResource.new("Total Instances", total_instances, maximum_total_instances, nil, "")}

    quota_resources.each_value do |quota_resource|
      if Quota.no_limit(quota_resource.max)
        quota_resource.max = "No Limit"
        quota_resource.available = "N\A"
      else
        quota_resource.available = quota_resource.max - quota_resource.used
        if quota_resource.available < 0
          quota_resource.available = quota_resource.available * -1
          quota_resource.available = "OverLimit By: " + quota_resource.available.to_s
        end
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
