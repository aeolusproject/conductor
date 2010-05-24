class InstanceObserver < ActiveRecord::Observer

  def after_save(an_instance)
    if an_instance.changed?
      change = an_instance.changes['state']
      if change
        update_timestamps(change[0], change[1], an_instance)
      end
    end
  end

  def update_timestamps(state_from, state_to, an_instance)
    if state_to == Instance::STATE_RUNNING
      an_instance.time_last_start = Time.now
    elsif state_from == Instance::STATE_RUNNING && state_to == Instance::STATE_STOPPED
      an_instance.acc_run_time = an_instance.acc_run_time + (Time.now - an_instance.time_last_start)
    end
  end

end

InstanceObserver.instance