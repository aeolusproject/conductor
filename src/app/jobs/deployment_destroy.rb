class DeploymentDestroy < Struct.new(:deployment)

  def perform
    deployment.stop_instances_and_destroy!
  end


  def error(job,exception)
    deployment.events << Event.create(
                          :source => deployment,
                          :event_time => DateTime.now,
                          :status_code => 'destroy_failed',
                          :summary => I18n.t("deployments.events.destroy_failed", :deployment => deployment.name, :exception => exception.message))
  end
end