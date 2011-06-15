class InstanceObserver < ActiveRecord::Observer

  ACTIVE_STATES = [ Instance::STATE_PENDING, Instance::STATE_RUNNING, Instance::STATE_SHUTTING_DOWN, Instance::STATE_STOPPED ]

  def before_save(an_instance)
    if an_instance.changed?
      change = an_instance.changes['state']
      if change
        update_state_timestamps(change[1], an_instance)
        update_accumulative_state_time(change[0], an_instance)
        update_quota(change[0], change[1], an_instance)
      end
    end
  end

  def update_state_timestamps(state_to, an_instance)
    case state_to
      when Instance::STATE_PENDING then an_instance.time_last_pending = Time.now
      when Instance::STATE_RUNNING then an_instance.time_last_running = Time.now
      when Instance::STATE_SHUTTING_DOWN then an_instance.time_last_shutting_down = Time.now
      when Instance::STATE_STOPPED then an_instance.time_last_stopped = Time.now
    end
  end

  def update_accumulative_state_time(state_from, an_instance)
    case state_from
      when Instance::STATE_PENDING then an_instance.acc_pending_time += Time.now - an_instance.time_last_pending
      when Instance::STATE_RUNNING then an_instance.acc_running_time += Time.now - an_instance.time_last_running
      when Instance::STATE_SHUTTING_DOWN then an_instance.acc_shutting_down_time += Time.now - an_instance.time_last_shutting_down
      when Instance::STATE_STOPPED then an_instance.acc_stopped_time += Time.now - an_instance.time_last_stopped
    end
  end

  def update_quota(state_from, state_to, an_instance)

    hwp = an_instance.hardware_profile
    pool = an_instance.pool
    user = an_instance.owner
    provider_account = an_instance.provider_account

    [provider_account, pool, user].each do |parent|
      if parent
        quota = parent.quota
        if quota
	  if state_to == Instance::STATE_RUNNING
	    quota.running_instances += 1
	  elsif state_from == Instance::STATE_RUNNING
	    quota.running_instances -= 1
	  end

	  if state_from != nil
	    if !ACTIVE_STATES.include?(state_from) && ACTIVE_STATES.include?(state_to)
	      quota.total_instances += 1
      elsif ACTIVE_STATES.include?(state_from) && !ACTIVE_STATES.include?(state_to)
	      quota.total_instances -= 1
	    end
          end
          quota.save!
        end
      end
    end
  end

  def after_create(instance)
    event = Event.new(:source => instance, :event_time => instance.created_at,
                      :summary => "created")
    event.save!
  end

  def after_update(instance)
    # we try to generate unique key only when instance is running
    # and provider_account for this instance has instance_key (provider account
    # instance_key is used as default ssh key when instance is launched)
    if instance.state_changed? and instance.state == Instance::STATE_RUNNING and
      not instance.instance_key and instance.provider_account and instance.provider_account.instance_key
        instance.delay.create_unique_key
    end

    if instance.state_changed?
      event = Event.new(:source => instance, :event_time => DateTime.now,
                        :summary => "state changed to #{instance.state}")
      event.save!
    end
  end

end

InstanceObserver.instance
