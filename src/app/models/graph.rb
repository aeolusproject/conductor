#
# Copyright (C) 2011 Red Hat, Inc.
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

class Graph
  attr_accessor :svg

  QOS_AVG_TIME_TO_SUBMIT = "qos_avg_time_to_submit"
  QUOTA_INSTANCES_IN_USE = "quota_instances_in_use"
  INSTANCES_BY_PROVIDER_PIE = "instances_by_provider_pie"

  # Quota Usage Graphs
  QUOTA_USAGE_RUNNING_INSTANCES = "quota_utilization_running_instances"
  QUOTA_USAGE_RUNNING_MEMORY = "quota_utilization_running_memory"
  QUOTA_USAGE_RUNNING_CPUS = "quota_utilization_running_cpus"
  QUOTA_USAGE_TOTAL_INSTANCES = "quota_utilization_total_instances"
  QUOTA_USAGE_TOTAL_STORAGE = "quota_utilization_total_storage"
  QUOTA_USAGE_OVERALL = "quota_utilization_overall"

  def initialize
    @svg = ""
  end

  def self.get_quota_usage_graph_name(resource_name)
    case resource_name
      when Quota::RESOURCE_RUNNING_INSTANCES
        return QUOTA_USAGE_RUNNING_INSTANCES
      when Quota::RESOURCE_RUNNING_MEMORY
        return QUOTA_USAGE_RUNNING_MEMORY
      when  Quota::RESOURCE_RUNNING_CPUS
        return QUOTA_USAGE_RUNNING_CPUS
      when Quota::RESOURCE_TOTAL_INSTANCES
        return QUOTA_USAGE_TOTAL_INSTANCES
      when Quota::RESOURCE_TOTAL_STORAGE
        return QUOTA_USAGE_TOTAL_STORAGE
      when Quota::RESOURCE_OVERALL
        return QUOTA_USAGE_OVERALL
      else
        return nil
    end
  end
end
