class UpdateStateForExistingDeployments < ActiveRecord::Migration
  def self.up
    Deployment.where(:state => nil).each do |d|
      d.update_attribute(:state, get_deployment_state(d))
    end
  end

  def self.down
  end

  def self.get_deployment_state(deployment)
    if deployment.instances.all? {|i| i.inactive?}
      Deployment::STATE_STOPPED
    elsif deployment.all_instances_running?
      Deployment::STATE_RUNNING
    elsif deployment.instances.all? { |i| [Instance::STATE_NEW,
          Instance::STATE_PENDING, Instance::STATE_RUNNING].include?(i.state) }
      Deployment::STATE_PENDING
    elsif deployment.instances.all? { |i| [Instance::STATE_RUNNING,
          Instance::STATE_SHUTTING_DOWN,
          Instance::STATE_STOPPED].include?(i.state) }
      Deployment::STATE_SHUTTING_DOWN
    else
      Deployment::STATE_INCOMPLETE
    end
  end
end
