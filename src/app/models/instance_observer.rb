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

class InstanceObserver < ActiveRecord::Observer

  ACTIVE_STATES = [ Instance::STATE_PENDING, Instance::STATE_RUNNING, Instance::STATE_SHUTTING_DOWN, Instance::STATE_STOPPED ]
  RUNNING_STATES = [ Instance::STATE_PENDING, Instance::STATE_RUNNING, Instance::STATE_SHUTTING_DOWN ]

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
    pool = an_instance.pool
    pool_family = pool.pool_family
    user = an_instance.owner
    provider_account = an_instance.provider_account

    [provider_account, pool_family, pool, user].each do |parent|
      if parent
        # Since pool and pool_family are related, updating one can cause the other to become stale
        parent.reload if [Pool, ProviderAccount].include? parent.class
        quota = parent.quota
        if quota
          if !RUNNING_STATES.include?(state_from) && RUNNING_STATES.include?(state_to)
            quota.running_instances += 1
          elsif RUNNING_STATES.include?(state_from) && !RUNNING_STATES.include?(state_to)
            quota.running_instances -= 1
          end
          quota.transaction do
            quota.lock!
            if !RUNNING_STATES.include?(state_from) && RUNNING_STATES.include?(state_to)
              quota.running_instances += 1
            elsif RUNNING_STATES.include?(state_from) && !RUNNING_STATES.include?(state_to)
              quota.running_instances -= 1
            end

            if !ACTIVE_STATES.include?(state_from) && ACTIVE_STATES.include?(state_to)
              quota.total_instances += 1
            elsif ACTIVE_STATES.include?(state_from) && !ACTIVE_STATES.include?(state_to)
              quota.total_instances -= 1
            end
            quota.save!
           end
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
    # This can get stale, so reload it -- if it exists
    instance.deployment.reload if instance.deployment
    if instance.state_changed?
      instance.deployment.update_state(instance) if instance.deployment
      event = Event.new(:source => instance, :event_time => DateTime.now,
                        :summary => "state changed to #{instance.state}",
                        :change_hash => instance.changes, :status_code => instance.state)
      event.save!
      if instance.state == Instance::STATE_RUNNING && instance.deployment
        event2 = Event.new(:source => instance.deployment, :event_time => DateTime.now,
                        :status_code => "first_running", :summary => "1st instance is running",
                        :change_hash => instance.changes) if instance.first_running?
        event3 = Event.new(:source => instance.deployment, :event_time => DateTime.now,
                        :status_code => "all_running", :summary => "All instances are running",
                        :change_hash => instance.changes) if instance.deployment.all_instances_running?
        event2.save! if event2
        event3.save! if event3
      elsif (instance.state == Instance::STATE_STOPPED || instance.state == Instance::STATE_ERROR) && instance.deployment
        if instance.deployment.any_instance_running? && !(instance.deployment.events.empty?)
          event4 = Event.new(:source => instance.deployment, :event_time => DateTime.now,
                             :status_code => "some_stopped", :summary => "Some instances are stopped",
                             :change_hash => instance.changes) if instance.deployment.events.lifetime.last{|e|e.status_code == :all_running}
        else
          event4 = Event.new(:source => instance.deployment, :event_time => DateTime.now,
                             :status_code => "all_stopped", :summary => "All instances are stopped",
                             :change_hash => instance.changes)
        end
        event4.save! if event4
      elsif instance.state == Instance::STATE_VANISHED
        Event.create!(
          :source => instance, :event_time => Time.now,
          :status_code => 'vanished', :summary => "Instance disappeared from cloud provider"
        )
      end

    end
  end

  def after_save(instance)
    if instance.state_changed? and instance.state == Instance::STATE_STOPPED
      instance.instance_key.destroy if instance.instance_key

      if instance.deployment and
        instance.deployment.scheduled_for_deletion and
        instance.deployment.destroyable?

        instance.deployment.destroy
      end
    end
  end

end

InstanceObserver.instance
