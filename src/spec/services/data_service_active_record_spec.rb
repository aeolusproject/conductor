require 'spec_helper'

describe DataServiceActiveRecord do

  it "should calculate the total instance quota usage for a provider with a number of cloud accounts" do
    client = mock('DeltaCloud').as_null_object
    provider = Factory.build(:mock_provider)
    provider.stub!(:connect).and_return(client)
    provider.save!

    data = [[25, 10], [40, 20], [20, 20]]
    free = 0
    for i in 0..2
      quota = Factory(:quota, :maximum_total_instances => data[i][0], :total_instances => data[i][1])
      provider_account = Factory.build(:provider_account, :provider => provider, :quota => quota)
      provider_account.credentials_hash = {:username => "username" + i.to_s, :password => 'mockpassword'}
      provider_account.stub!(:valid_credentials?).and_return(true)
      provider_account.save!

      free += (data[i][0] - data[i][1])
    end

    data_points = DataServiceActiveRecord.provider_quota_usage(provider)
    data_points[0].should == DataServiceActiveRecord::TotalQuotaUsagePoint.new("username0", data[0][1])
    data_points[1].should == DataServiceActiveRecord::TotalQuotaUsagePoint.new("username1", data[1][1])
    data_points[2].should == DataServiceActiveRecord::TotalQuotaUsagePoint.new("username2", data[2][1])
    data_points[3].should == DataServiceActiveRecord::TotalQuotaUsagePoint.new("free", free)

  end

  it "should calculate the total number of instances and maximum number of instances of a cloud account" do
    client = mock('DeltaCloud').as_null_object
    provider = Factory.build(:mock_provider)
    provider.stub!(:connect).and_return(client)
    provider.save!


    quota = Factory(:quota,
                    :maximum_running_instances => 40,
                    :maximum_total_instances => 50,
                    :running_instances => 20,
                    :total_instances => 20)

    provider_account = Factory.build(:provider_account, :provider => provider, :quota => quota)
    provider_account.credentials_hash = {:username => 'test', :password =>'test'}
    provider_account.stub!(:valid_credentials?).and_return(true)
    provider_account.save!

    data_point = DataServiceActiveRecord.quota_usage(provider_account, Quota::RESOURCE_RUNNING_INSTANCES)
    data_point.should == DataServiceActiveRecord::QuotaUsagePoint.new(20, 40)

    data_point = DataServiceActiveRecord.quota_usage(provider_account, Quota::RESOURCE_TOTAL_INSTANCES)
    data_point.should == DataServiceActiveRecord::QuotaUsagePoint.new(20, 50)

    data_point = DataServiceActiveRecord.quota_usage(provider_account, Quota::RESOURCE_OVERALL)
    data_point.should == DataServiceActiveRecord::QuotaUsagePoint.new(20, 40)
  end

  it "should calculate the average, max and min task submission times" do
    pool = Factory(:pool)
    instance = Factory(:instance, :pool_id => pool.id)

    start_time = Time.utc(2010,"jan",1,20,15,1)
    for i in 1..10 do
      task = InstanceTask.new(:instance => instance,
                              :state => Task::STATE_PENDING,
                              :failure_code => nil,
                              :task_target_id => instance.id,
                              :type => "InstanceTask",
                              :action => InstanceTask::ACTION_CREATE)
      task.save!

      task.created_at = start_time
      task.time_submitted = start_time
      task.time_started = start_time + i
      task.save!
    end

    data_point = DataServiceActiveRecord.qos_task_submission_mean_max_min(pool, start_time, Time.now, InstanceTask::ACTION_CREATE)

    data_point.average.should == 5.5
    data_point.min.should == 1
    data_point.max.should == 10
  end

  it "should create data points for the average, max and min task submission times between two times at given intervals" do
    pool = Factory(:pool)
    instance = Factory(:instance, :pool_id => pool.id)

    expected_averages = [ 20, 40, 60, 80, 100]
    no_intervals = expected_averages.length
    interval_length = 30

    end_time = Time.utc(2010,"jan",1,20,15,1)
    start_time = end_time - (interval_length * no_intervals)

    generate_tasks(start_time, interval_length, instance, expected_averages)
    data_points = DataServiceActiveRecord.qos_task_submission_stats(pool, start_time, end_time, interval_length, InstanceTask::ACTION_CREATE)

    for i in 0...data_points.length
      average_time = expected_averages[i]
      dp = data_points[i]

      dp.average.should == average_time
      # The multiplications could be set as static numbers but are left as calculations for easier understanding of code
      dp.max.should == (average_time / 10) * 2 * 9
      dp.min.should == (average_time / 10) * 2
    end
  end

  it "should create data points for mean, max and min task submission times at given intervals for a provider with multiple accounts" do
    pool = Factory :pool

    expected_averages = []
    expected_averages[0] = [ 20, 40, 60, 80, 100]
    expected_averages[1] = [ 40, 60, 80, 100, 120]
    expected_averages[2] = [ 60, 80, 100, 120, 140]

    no_intervals = expected_averages.length
    interval_length = 30
    end_time = Time.utc(2010,"jan",1,20,15,1)
    start_time = end_time - (interval_length * no_intervals)

    client = mock('DeltaCloud').as_null_object
    provider = Factory.build(:mock_provider)
    provider.stub!(:connect).and_return(client)
    provider.save!

    provider_accounts = []
    expected_averages.each do |expected_average|
      provider_account = Factory.build(:provider_account, :provider => provider)
      provider_account.credentials_hash = { :username => "username" + expected_average[0].to_s, :password => 'mockpassword' }
      provider_account.stub!(:valid_credentials?).and_return(true)
      provider_account.save!

      instance = Factory(:instance, :provider_account_id => provider_account.id, :pool_id => pool.id)
      generate_tasks(start_time, interval_length, instance, expected_average)
    end

    data_points = DataServiceActiveRecord.qos_task_submission_stats(pool, start_time, end_time, interval_length, InstanceTask::ACTION_CREATE)

    for i in 0...data_points.length
      dp = data_points[i]
      dp.average.should == expected_averages[1][i]
      dp.max.should == (expected_averages[2][i] / 10) * 2 * 9
      dp.min.should == (expected_averages[0][i] / 10) * 2
    end
  end

  it "should create data points for mean, max, min instance runtimes" do
    interval_length = 1000

    start_time = Time.utc(2010,"jan",1,20,15,1)
    start_time1 = start_time + interval_length
    start_time2 = start_time1 + interval_length
    start_times = [start_time, start_time1, start_time2]

    end_time = start_time2 + interval_length

    runtime1 = [5, 10, 15, 20, 25]
    runtime2 = [10, 20, 30, 40, 50]
    runtime3 = [100, 200, 300, 400, 500]
    runtimes = [runtime1, runtime2, runtime3]

    pool = Factory(:pool)
    provider_account = Factory :mock_provider_account

    for i in 0..2 do
       runtimes[i].each do |runtime|
         instance = Factory(:instance, :pool => pool, :provider_account => provider_account, :state => Instance::STATE_STOPPED)
         instance.save!

         instance.time_last_pending = start_times[i] + (interval_length / 2)
         instance.time_last_running = start_times[i] + (interval_length / 2)
         instance.acc_running_time = runtime
         instance.save!
       end
    end

    stats = DataServiceActiveRecord.qos_instance_runtime_stats(provider_account, start_time, end_time, interval_length)
    stats[0].should == DataServiceActiveRecord::QoSDataPoint.new(start_times[0], 15, 25, 5)
    stats[1].should == DataServiceActiveRecord::QoSDataPoint.new(start_times[1], 30, 50, 10)
    stats[2].should == DataServiceActiveRecord::QoSDataPoint.new(start_times[2], 300, 500, 100)

  end

  it "should generate the mean max and min instance runtimes of instances for a given provider account or pool" do
    pool = Factory(:pool)

    provider_account = Factory :mock_provider_account

    start_time = Time.utc(2010,"jan",1,20,15,1)
    [50, 100, 150, 200, 250].each do |runtime|
      instance = Factory(:new_instance, :pool => pool, :provider_account => provider_account)
      instance.time_last_pending = start_time
      instance.time_last_running = start_time
      instance.acc_running_time = runtime
      instance.save!
    end

    expected_results = DataServiceActiveRecord::QoSDataPoint.new(start_time, 150, 250, 50)
    results = DataServiceActiveRecord.qos_instance_runtime_mean_max_min(pool, start_time, Time.now)
    results.should == expected_results
  end

  it "should calculate the average time it takes a provider to complete a task between two times" do
    pool = Factory(:pool)
    provider_account = Factory(:mock_provider_account)
    instance = Factory(:instance, :pool => pool, :provider_account => provider_account)

    start_time = Time.utc(2010,"jan",1,20,15,1)
    task_completion_times = [10, 20, 30, 40, 50]
    total_time = 0

    task_completion_times.each do |time|
      task = InstanceTask.new(:instance => instance,
                              :type => "InstanceTask",
                              :state => Task::STATE_FINISHED,
                              :failure_code => nil,
                              :action => InstanceTask::ACTION_CREATE,
                              :task_target_id => instance.id)
      task.save!

      task.created_at = start_time
      task.time_started = start_time
      task.time_ended = start_time + time
      task.save!

      total_time += time
    end

    expected_average_time = total_time / task_completion_times.length
    average_time = DataServiceActiveRecord.qos_task_completion_mean_max_min(provider_account.provider, start_time, Time.now, InstanceTask::ACTION_CREATE)

    average_time[:average].should == expected_average_time
    average_time[:min].should == 10
    average_time[:max].should == 50
  end

  it "should calculate the correct failure rate of instances starts for a particular pool or provider account" do
    start_time = Time.utc(2010,"jan",1,20,15,1)
    create_time = start_time + 1
    end_time = create_time + 1

    pool = Factory(:pool)
    provider_account = Factory :mock_provider_account
    instance = Factory(:instance, :pool => pool, :provider_account => provider_account)

    failures = 5
    non_failures = 20

    for i in 1..failures
      task = InstanceTask.new(:instance => instance,
                              :type => "InstanceTask",
                              :state => Task::STATE_FAILED,
                              :failure_code => Task::FAILURE_OVER_POOL_QUOTA,
                              :action => InstanceTask::ACTION_CREATE,
                              :task_target_id => instance.id)
      task.created_at = create_time
      task.save!
    end

    for i in 1..non_failures
      task = InstanceTask.new(:instance => instance,
                              :type => "InstanceTask",
                              :state => Task::STATE_FINISHED,
                              :failure_code => nil,
                              :action => InstanceTask::ACTION_CREATE,
                              :task_target_id => instance.id)
      task.created_at = create_time
      task.save!
    end

    date = DataServiceActiveRecord.failure_rate(pool, start_time, end_time, Task::FAILURE_OVER_POOL_QUOTA)
    date.failure_rate.should == (100 / (non_failures + failures)) * failures
  end

  it "should create data points for failure rates of instances between two times at given intervals" do
    interval_length = 1000

    start_time = Time.utc(2010,"jan",1,20,15,1)
    start_time1 = start_time + interval_length
    start_time2 = start_time1 + interval_length
    start_times = [start_time, start_time1, start_time2]

    end_time = start_time2 + interval_length

    failures = [5, 10, 15]
    number_of_instances = 20

    pool = Factory(:pool)
    provider_account = Factory :mock_provider_account
    instance = Factory(:instance, :pool => pool, :provider_account => provider_account)

    for i in 0..2
      for j in 1..failures[i]
        task = InstanceTask.new(:instance => instance,
                                :type => "InstanceTask",
                                :state => Task::STATE_FAILED,
                                :failure_code => Task::FAILURE_OVER_POOL_QUOTA,
                                :action => InstanceTask::ACTION_CREATE,
                                :task_target_id => instance.id)
        task.created_at = start_times[i]
        task.time_submitted = start_times[i]
        task.save!
      end

      non_failures = number_of_instances - failures[i]
      for j in 1..non_failures
        task = InstanceTask.new(:instance => instance,
                                :type => "InstanceTask",
                                :state => Task::STATE_FINISHED,
                                :failure_code => nil,
                                :action => InstanceTask::ACTION_CREATE,
                                :task_target_id => instance.id)
        task.created_at = start_times[i]
        task.time_submitted = start_times[i]
        task.save!
      end
    end

    data = DataServiceActiveRecord.qos_failure_rate_stats(pool, start_time, end_time, interval_length, Task::FAILURE_OVER_POOL_QUOTA)
    data[0].should == DataServiceActiveRecord::QoSFailureRatePoint.new(start_time, 25)
    data[1].should == DataServiceActiveRecord::QoSFailureRatePoint.new(start_time1, 50)
    data[2].should == DataServiceActiveRecord::QoSFailureRatePoint.new(start_time2, 75)
  end

  def generate_tasks(start_time, interval_length, instance, expected_averages)
    interval_time = start_time
    expected_averages.each do |avg|
      submission_time = interval_time + (interval_length / 2)
      for i in 1..9 do
        started_time = submission_time + ((avg / 10) * 2) * i

        task = InstanceTask.new(:instance => instance,
                                :type => "InstanceTask",
                                :state => Task::STATE_QUEUED,
                                :failure_code => nil,
                                :action => InstanceTask::ACTION_CREATE,
                                :task_target_id => instance.id)
        task.created_at = submission_time
        task.time_submitted = submission_time
        task.time_started = started_time
        task.save!
      end
      interval_time += interval_length
    end
  end
end

