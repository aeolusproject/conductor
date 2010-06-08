class Graph
  attr_accessor :svg

  QOS_AVG_TIME_TO_SUBMIT = "qos_avg_time_to_submit"
  QUOTA_INSTANCES_IN_USE = "quota_instances_in_use"
  INSTANCES_BY_PROVIDER_PIE = "instances_by_provider_pie"
  def initialize
    @svg = ""
  end
end
