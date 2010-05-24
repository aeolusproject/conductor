class TaskObserver < ActiveRecord::Observer

  END_STATES = [ Task::STATE_CANCELED, Task::STATE_FAILED, Task::STATE_FINISHED ]

  def after_save(a_task)
    if a_task.changed?
      change = a_task.changes['state']
      if change
        update_timestamp(change[0], change[1], a_task)
      end
    end
  end

  def update_timestamp(state_from, state_to, a_task)
    if state_to == Task::STATE_RUNNING
      a_task.time_started = Time.now
    elsif state_to == Task::STATE_PENDING
      a_task.time_submitted = Time.now
    elsif END_STATES.include?(state_to)
      a_task.time_ended = Time.now
    end
  end

end

TaskObserver.instance