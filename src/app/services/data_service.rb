class DataService

  QoSDataPoint = Struct.new(:time, :average, :max, :min)
  QuotaUsagePoint = Struct.new(:used, :max)
  TotalQuotaUsagePoint = Struct.new(:name, :no_instances)

  # This will return array of data points between start and end, if there is a data point where the interval start + interval end
  # is greater than the end time, it will be ignored
  # Example:
  # start = 12.30, end = 12.32, interval = 45secs
  # Intervals: 12.30.00 - 12.30.45, 12.30.45 - 12.31.30 will be returned.  Interval 12.31.30 - 12.32.15 will not
  def self.qos_task_submission_stats(start_time, end_time, interval_length, parent, action)

    instances = []

    if parent.class == Provider
      cloud_accounts = CloudAccount.find(:all, :conditions => {:provider_id => parent.id})
      cloud_accounts.each do |cloud_account|
        instances.concat(instances)
      end
    elsif parent.class == Pool || parent.class == CloudAccount
       instances = parent.instances
    else
      return nil
    end

    return calculate_qos_task_submission_stats(start_time, end_time, interval_length, instances, action)
  end

  def self.tasks_submissions_mean_max_min(time, tasks)

    first_pass = true

    total_time = nil
    maximum_time = nil
    minimum_time = nil

    tasks.each do |task|

      if(first_pass == true)
        total_time = task.submission_time
        maximum_time = task.submission_time
        minimum_time = task.submission_time
        first_pass = false
      else
        total_time += task.submission_time

        if task.submission_time > maximum_time
          maximum_time = task.submission_time
        end

        if task.submission_time< minimum_time
          minimum_time = task.submission_time
        end
      end

    end
    average_time = total_time / tasks.length

    return QoSDataPoint.new(time, average_time, maximum_time, minimum_time)
  end

  # Returns the Used and Maximum Resource Usage
  def self.quota_utilisation(parent, resource_name)
    quota = parent.quota

    case resource_name
      when Quota::RESOURCE_RUNNING_INSTANCES
        return QuotaUsagePoint.new(quota.running_instances, quota.maximum_running_instances)
      when Quota::RESOURCE_RUNNING_MEMORY
        return QuotaUsagePoint.new(quota.running_memory.to_f, quota.maximum_running_memory.to_f)
      when Quota::RESOURCE_RUNNING_CPUS
        return QuotaUsagePoint.new(quota.running_cpus.to_f, quota.maximum_running_cpus.to_f)
      when Quota::RESOURCE_TOTAL_INSTANCES
        return QuotaUsagePoint.new(quota.total_instances, quota.maximum_total_instances)
      when Quota::RESOURCE_TOTAL_STORAGE
        return QuotaUsagePoint.new(quota.total_storage.to_f, quota.maximum_total_storage.to_f)
      when Quota::RESOURCE_OVERALL
        return self.overall_usage(parent)
      else
        return nil
    end
  end

  def self.overall_usage(parent)
    usage_points = []
    Quota::RESOURCE_NAMES.each do |resource_name|
      usage_points << quota_utilisation(parent, resource_name)
    end

    worst_case = nil
    usage_points.each do |usage_point|
      if worst_case
        if ((100 / worst_case.max) * worst_case.used) < ((100 / usage_point.max) * usage_point.used)
          worst_case = usage_point
        end
      else
        worst_case = usage_point
      end
    end
    return worst_case
  end

  def self.total_quota_utilisation(provider)
    data_points = []
    free_instances = 0

    cloud_accounts = CloudAccount.find(:all, :conditions => {:provider_id => provider.id})
    cloud_accounts.each do |cloud_account|
      quota = cloud_account.quota
      if quota
        data_points << TotalQuotaUsagePoint.new(cloud_account.username, quota.total_instances)
        free_instances += (quota.maximum_total_instances - quota.total_instances)
      end
    end
    data_points << TotalQuotaUsagePoint.new("free", free_instances)
    return data_points
  end

  private
  def self.calculate_qos_task_submission_stats(start_time, end_time, interval_length, instances, action)

    data = []
    until start_time > (end_time - interval_length) do
      interval_time = start_time + interval_length

      tasks = Task.find(:all, :conditions => {  :time_submitted => start_time..interval_time,
                                                :time_started => start_time..Time.now,
                                                :failure_code => nil,
                                                :action => action,
                                                :task_target_id => instances
                                             })
      if tasks.length > 0
        data << tasks_submissions_mean_max_min(start_time, tasks)
      else
        data << QoSDataPoint.new(start_time, 0, 0, 0)
      end

      start_time = interval_time
    end

    return data
  end

end
