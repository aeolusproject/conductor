namespace :db do
  desc "Populates a Cloud Account with historical tasks, takes a cloud account id, user id, the time period in hours, and the
        number of tasks to create"

  PROB_LONG_RESPONSE = 8
  PROB_MEDIUM_RESPONSE = 70
  PROB_SHORT_REPONSE = 20
  PROB_FAILURE = 2

  LONG_RESPONSE_MIN = 7
  LONG_RESPONSE_MAX = 15

  MEDIUM_RESPONSE_MIN = 2
  MEDIUM_RESPONSE_MAX = 5

  SHORT_RESPONSE_MIN = 1
  SHORT_RESPONSE_MAX = 2

  REQUESTS_PER_MINUTE = 1

  END_TIME = Time.now

  TASK_ACTIONS = [ "create", "start", "stop", "reboot", "destroy" ]

  SHORT_ACC = PROB_SHORT_REPONSE + PROB_FAILURE
  MEDIUM_ACC = PROB_MEDIUM_RESPONSE + PROB_SHORT_REPONSE + PROB_FAILURE

  task :demo_data, :cloud_account_id, :user_id, :time_period, :number_of_tasks, :needs => :environment do |t, args|

    @time_scale = args[:time_period].to_f * 60 * 60
    @number_of_tasks = args[:number_of_tasks]

    puts @number_of_tasks

    cloud_account = CloudAccount.find(args[:cloud_account_id])
    user = User.find(args[:user_id])

    instance = create_instance()

    started_at = Time.now
    create_tasks(instance, user)
    ended_at = Time.now

    print_stats(started_at, ended_at)
  end

  def create_instance()
    instance = Instance.new({:name => "instance",
                             :hardware_profile_id => HardwareProfile.find(:first),
                             :image_id => Image.find(:first),
                             :state => Instance::STATE_NEW,
                             :pool_id => 1
                            })
    instance.save!
    return instance
  end

  def print_stats(started_at, ended_at)
    run_time = ended_at - started_at
    tasks_create_time = run_time / @number_of_tasks.to_f
    tasks_per_minute = 60 / tasks_create_time

    puts "Total Run Time (s): " + run_time.to_s()
    puts "Average Create Time (s): " + tasks_create_time.to_s()
    puts "Task Created Per Minute: " + tasks_per_minute.to_s()
  end

  def create_task(instance, user)
    task = Task.new({})
    task.user = user
    task.type = "InstanceTask"
    task.action = TASK_ACTIONS[rand(TASK_ACTIONS.length)]
    task.task_target_id = instance.id
    task.created_at = END_TIME - (@time_scale.to_f)
    return task
  end

  def create_tasks(instance, user)
    for i in 1..@number_of_tasks.to_f do
      task = create_task(instance, user)

      random = 1 + rand(100)
      if random <= PROB_FAILURE
        task.state = Task::STATE_FAILED
        task.failure_code = Task::FAILURE_CODES[rand(Task::FAILURE_CODES.length)]
      else
        task.state = Task::STATE_FINISHED

        time_submitted = END_TIME - rand(1 + (@time_scale.to_f))
        task.time_submitted = time_submitted

        task.time_started = calculate_time_started(time_submitted, random)

        time_ended = task.time_started + rand(20) + 1
        task.time_ended = time_ended
      end
      task.save!
    end
  end

  def calculate_time_started(time_submitted, random)
    time_started = nil

    if random <= SHORT_ACC
      time_started = time_submitted + (SHORT_RESPONSE_MIN + rand(SHORT_RESPONSE_MAX - SHORT_RESPONSE_MIN + 1))
    elsif random <= MEDIUM_ACC
      time_started = time_submitted + (MEDIUM_RESPONSE_MIN + rand(MEDIUM_RESPONSE_MAX - MEDIUM_RESPONSE_MIN + 1))
    else
      time_started = time_submitted + (LONG_RESPONSE_MIN + rand(LONG_RESPONSE_MAX - LONG_RESPONSE_MIN + 1))
    end

    return time_started
  end

end