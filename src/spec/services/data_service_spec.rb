require 'spec_helper'

describe DataService do

  it "should calculate the total instance quota usage for a provider with a numbner of cloud accounts" do
    client = mock('DeltaCloud', :null_object => true)
    provider = Factory.build(:mock_provider)
    provider.stub!(:connect).and_return(client)
    provider.save!

    data = [[25, 10], [40, 20], [20, 20]]
    free = 0
    for i in 0..2
      cloud_account = Factory.build(:cloud_account, :provider => provider, :username => "username" + i.to_s)
      cloud_account.stub!(:valid_credentials?).and_return(true)
      cloud_account.save!

      quota = Factory(:quota, :maximum_total_instances => data[i][0], :total_instances => data[i][1])
      cloud_account.quota_id = quota.id
      cloud_account.save!

      free += (data[i][0] - data[i][1])
    end

    data_points = DataService.total_quota_utilisation(provider)
    data_points[0].should == DataService::TotalQuotaUsagePoint.new("username0", data[0][1])
    data_points[1].should == DataService::TotalQuotaUsagePoint.new("username1", data[1][1])
    data_points[2].should == DataService::TotalQuotaUsagePoint.new("username2", data[2][1])
    data_points[3].should == DataService::TotalQuotaUsagePoint.new("free", free)

  end

  it "should calculate the total number of instances and maximum number of instances of a cloud account" do
    client = mock('DeltaCloud', :null_object => true)
    provider = Factory.build(:mock_provider)
    provider.stub!(:connect).and_return(client)
    provider.save!

    cloud_account = Factory.build(:cloud_account, :provider => provider)
    cloud_account.stub!(:valid_credentials?).and_return(true)
    cloud_account.save!

    quota = Factory(:quota,
                    :maximum_running_instances => 40,
                    :maximum_running_memory => 10240,
                    :maximum_running_cpus => 10,
                    :maximum_total_instances => 50,
                    :maximum_total_storage => 500,
                    :running_instances => 20,
                    :running_memory => 4096,
                    :running_cpus => 7,
                    :total_instances => 20,
                    :total_storage => 499)
    cloud_account.quota_id = quota.id

    data_point = DataService.quota_utilisation(cloud_account, Quota::RESOURCE_RUNNING_INSTANCES)
    data_point.should == DataService::QuotaUsagePoint.new(20, 40)

    data_point = DataService.quota_utilisation(cloud_account, Quota::RESOURCE_RUNNING_MEMORY)
    data_point.should == DataService::QuotaUsagePoint.new(4096, 10240)

    data_point = DataService.quota_utilisation(cloud_account, Quota::RESOURCE_RUNNING_CPUS)
    data_point.should == DataService::QuotaUsagePoint.new(7, 10)

    data_point = DataService.quota_utilisation(cloud_account, Quota::RESOURCE_TOTAL_INSTANCES)
    data_point.should == DataService::QuotaUsagePoint.new(20, 50)

    data_point = DataService.quota_utilisation(cloud_account, Quota::RESOURCE_TOTAL_STORAGE)
    data_point.should == DataService::QuotaUsagePoint.new(499, 500)

    data_point = DataService.quota_utilisation(cloud_account, Quota::RESOURCE_OVERALL)
    data_point.should == DataService::QuotaUsagePoint.new(499, 500)
  end

  it "should calculate the average, max and min task submission times" do
    tasks = []
    instance = Factory :instance

    for i in 1..10 do
      time = Time.utc(2010,"jan",1,20,15,1)
      task = Task.new(:instance => instance, :type => "InstanceTask", :state => Task::STATE_PENDING, :failure_code => nil)
      task.time_submitted = time
      time += i
      task.time_started = time
      task.save
      tasks << task
    end

    data_point = DataService.tasks_submissions_mean_max_min(Time.now, tasks)

    data_point.average.should == 5.5
    data_point.min.should == 1
    data_point.max.should == 10
  end

  it "should create data points for the average, max and min task submission times between two times at given intervals" do
    pool = Factory :pool
    instance = Factory(:instance, :pool_id => pool.id)

    expected_averages = [ 20, 40, 60, 80, 100]
    no_intervals = expected_averages.length
    interval_length = 30

    end_time = Time.utc(2010,"jan",1,20,15,1)
    start_time = end_time - (interval_length * no_intervals)

    generate_tasks(start_time, interval_length, instance, expected_averages)

    data_points = DataService.qos_task_submission_stats(start_time, end_time, interval_length, pool, InstanceTask::ACTION_CREATE)

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

    client = mock('DeltaCloud', :null_object => true)
    provider = Factory.build(:mock_provider)
    provider.stub!(:connect).and_return(client)
    provider.save!

    cloud_accounts = []
    expected_averages.each do |expected_average|
      cloud_account = Factory.build(:cloud_account, :provider => provider, :username => "username" + expected_average[0].to_s)
      cloud_account.stub!(:valid_credentials?).and_return(true)
      cloud_account.save!

      instance = Factory(:instance, :cloud_account_id => cloud_account.id, :pool_id => pool.id)
      generate_tasks(start_time, interval_length, instance, expected_average)
    end

    data_points = DataService.qos_task_submission_stats(start_time, end_time, interval_length, pool, InstanceTask::ACTION_CREATE)

    for i in 0...data_points.length
      dp = data_points[i]
      dp.average.should == expected_averages[1][i]
      dp.max.should == (expected_averages[2][i] / 10) * 2 * 9
      dp.min.should == (expected_averages[0][i] / 10) * 2
    end
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
