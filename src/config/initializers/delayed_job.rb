require 'delayed_job'

Delayed::Worker.backend = :active_record
Delayed::Worker.destroy_failed_jobs = false
#Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 2
#Delayed::Worker.max_run_time = 5.minutes
#Delayed::Worker.read_ahead = 10

# in test env jobs are not delayed and are executed directly
Delayed::Worker.delay_jobs = !Rails.env.test?
