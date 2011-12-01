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
