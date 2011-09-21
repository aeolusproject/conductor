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

class DataServiceActiveRecord

  # Structures for holding graph data
  QoSDataPoint = Struct.new(:time, :average, :max, :min)

  QuotaUsagePoint = Struct.new(:used, :max)

  TotalQuotaUsagePoint = Struct.new(:name, :no_instances)

  QoSFailureRatePoint = Struct.new(:time, :failure_rate)

  def self.qos_task_submission_stats(parent, start_time, end_time, interval_length, action)
    return qos_time_stats(parent, start_time, end_time, interval_length, {:action => action}, TASK_SUBMISSION_TIMES)
  end

  def self.qos_task_completion_stats(parent, start_time, end_time, interval_length, action)
    return qos_time_stats(parent, start_time, end_time, interval_length, {:action => action}, TASK_COMPLETION_TIMES)
  end

  def self.qos_task_submission_mean_max_min(parent, start_time, end_time, action)
    return qos_times_mean_max_min(parent, start_time, end_time, action, TASK_SUBMISSION_TIMES)
  end

  def self.qos_task_completion_mean_max_min(parent, start_time, end_time, action)
    return qos_times_mean_max_min(parent, start_time, end_time, action, TASK_COMPLETION_TIMES)
  end

  def self.qos_instance_runtime_stats(parent, start_time, end_time, interval_length)
    return qos_time_stats(parent, start_time, end_time, interval_length, nil, INSTANCE_RUN_TIMES)
  end

  def self.qos_instance_runtime_mean_max_min(parent, start_time, end_time)
    return qos_times_mean_max_min(parent, start_time, end_time, nil, INSTANCE_RUN_TIMES)
  end

  def self.qos_failure_rate(parent, start_time, end_time, failure_code)
    return failure_rate(parent, start_time, end_time, failure_code)
  end

  def self.qos_failure_rate_stats(parent, start_time, end_time, interval_length, failure_code)
    qos_time_stats(parent, start_time, end_time, interval_length, {:failure_code => failure_code}, FAILURE_RATE)
  end

  # Returns the Used and Maximum Resource Usage
  def self.quota_usage(parent, resource_name)
    if parent
      quota = parent.quota
      if quota
        case resource_name
          when Quota::RESOURCE_RUNNING_INSTANCES
            return QuotaUsagePoint.new(quota.running_instances, quota.maximum_running_instances)
          when Quota::RESOURCE_TOTAL_INSTANCES
            return QuotaUsagePoint.new(quota.total_instances, quota.maximum_total_instances)
          when Quota::RESOURCE_OVERALL
            return self.overall_usage(parent)
          else
            return nil
        end
      end
    end
    return nil
  end

  def self.provider_quota_usage(provider)
    data_points = []
    free_instances = 0

    provider_accounts = ProviderAccount.find(:all, :conditions => {:provider_id => provider.id})
    provider_accounts.each do |provider_account|
      quota = provider_account.quota
      if quota
        data_points << TotalQuotaUsagePoint.new(provider_account.credentials_hash['username'], quota.total_instances)
        free_instances += (quota.maximum_total_instances - quota.total_instances)
      end
    end
    data_points << TotalQuotaUsagePoint.new("free", free_instances)
    return data_points
  end

  #####################
  ## PRIVATE METHODS ##
  #####################
  private

  TASK_SUBMISSION_TIMES = "TASK_SUBMISSION_TIMES"

  TASK_COMPLETION_TIMES = "TASK_COMPLETION_TIMES"

  INSTANCE_RUN_TIMES = "INSTANCE_RUN_TIMES"

  FAILURE_RATE = "FAILURE_RATE"

  def self.qos_time_stats(parent, start_time, end_time, interval_length, params, compare_field)
    data = []
    until start_time > (end_time - interval_length) do
      interval_time = start_time + interval_length

      case compare_field
        when FAILURE_RATE
          data << failure_rate(parent, start_time, interval_time,  params[:failure_code])
        when INSTANCE_RUN_TIMES
          data << qos_times_mean_max_min(parent, start_time, interval_time, nil, compare_field)
        when TASK_COMPLETION_TIMES
          data << qos_times_mean_max_min(parent, start_time, interval_time, params[:action], compare_field)
        when TASK_SUBMISSION_TIMES
          data << qos_times_mean_max_min(parent, start_time, interval_time, params[:action], compare_field)
      end

      start_time = interval_time
    end
    return data
  end

  # Calculates the mean, max and min times, for the tasks state time, e.g. submission, completion, etc...
  def self.qos_times_mean_max_min(parent, start_time, end_time, action, compare_field)
    first_pass = true

    total_time = nil
    maximum_time = nil
    minimum_time = nil

    case compare_field
      when TASK_SUBMISSION_TIMES
        list = get_compare_tasks(parent, compare_field, start_time, end_time, action)
      when TASK_COMPLETION_TIMES
        list = get_compare_tasks(parent, compare_field, start_time, end_time, action)
      when INSTANCE_RUN_TIMES
        list = get_compare_instances(parent, compare_field, start_time, end_time)
      else
        return nil
    end

    list.each do |l|
      case compare_field
        when TASK_SUBMISSION_TIMES
          compare_time = l.submission_time
        when TASK_COMPLETION_TIMES
          compare_time = l.runtime
        when INSTANCE_RUN_TIMES
          compare_time = l.total_state_time(Instance::STATE_RUNNING)
        else
          return nil
      end

      if(first_pass == true)
        total_time = compare_time
        maximum_time = compare_time
        minimum_time = compare_time
        first_pass = false
      else
        total_time += compare_time

        if compare_time > maximum_time
          maximum_time = compare_time
        end

        if compare_time < minimum_time
          minimum_time = compare_time
        end
      end
    end

    if total_time == nil
      average_time = nil
    elsif total_time == 0
      average_time = 0
    else
      average_time = total_time / list.length
    end

    return QoSDataPoint.new(start_time, average_time, maximum_time, minimum_time)
  end

  def self.get_parent_instances(parent)
    instances = []

    if parent.class == Provider
      cloud_accounts = ProviderAccount.find(:all, :conditions => {:provider_id => parent.id})
      cloud_accounts.each do |cloud_account|
        instances.concat(cloud_account.instances)
      end
    elsif parent.class == Pool || parent.class == ProviderAccount
       instances = parent.instances
    else
      return nil
    end

    return instances
  end

  def self.get_compare_tasks(parent, compare_field, start_time, end_time, action)
    instances = get_parent_instances(parent)
    case compare_field
      when TASK_SUBMISSION_TIMES
        return Task.find(:all, :conditions => {:time_submitted => start_time...end_time,
                                                :time_started => start_time..Time.now,
                                                :failure_code => nil,
                                                :action => action,
                                                :task_target_id => instances })
      when TASK_COMPLETION_TIMES
        return Task.find(:all, :conditions => {:time_started => start_time...end_time,
                                               :time_ended => start_time..Time.now,
                                               :failure_code => nil,
                                               :action => action,
                                               :task_target_id => instances,
                                               :state => Task::STATE_FINISHED })
      else
        return nil
    end
  end

  # returns the failure rate of instance starts for instances associated with the parent, (pool/ProviderAccount) given the failure code
  def self.failure_rate(parent, start_time, end_time, failure_code)
    instances = get_parent_instances(parent)
    tasks = Task.find(:all, :conditions => {:created_at => start_time...end_time,
                                            :task_target_id => instances })

    failure_rate = 0
    if tasks.length > 0
      failed_tasks = tasks.find_all{ |task| task.failure_code == failure_code}
      if failed_tasks.length > 0
        failure_rate = (100.to_f / tasks.length.to_f) * failed_tasks.length.to_f
      end
    end
    return QoSFailureRatePoint.new(start_time, failure_rate)
  end

  def self.overall_usage(parent)
    usage_points = []
    Quota::RESOURCE_NAMES.each do |resource_name|
      usage_points << quota_usage(parent, resource_name)
    end

    worst_case = nil
    usage_points.each do |usage_point|
      if worst_case
        if worst_case.max == Quota::NO_LIMIT
          worst_case = usage_point
        elsif usage_point.max == Quota::NO_LIMIT
          # DO Nothing
        elsif ((100 / worst_case.max) * worst_case.used) < ((100 / usage_point.max) * usage_point.used)
          worst_case = usage_point
        end
      else
        worst_case = usage_point
      end
    end
    return worst_case
  end

  def self.get_compare_instances(parent, compare_field, start_time, end_time)
    instances = get_parent_instances(parent)
    case compare_field
      when INSTANCE_RUN_TIMES
        return  instances.find(:all, :conditions => {:time_last_pending => start_time...end_time,
                                                     :time_last_running => start_time..Time.now})
      else
        return nil
    end
  end

end
