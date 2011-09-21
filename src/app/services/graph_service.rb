#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

class GraphService

  require 'nokogiri'

  DATA_SERVICE = DataServiceActiveRecord

  def self.dashboard_quota (user,opts = {})
    #FIXME add permission checks to filter what graphs user can get
    graphs = Hash.new

    #if a specific cloud account is given, just return that cloud account's graph.
    #otherwise return all graphs user has permission to see.
    if opts[:cloud_account]
      cloud_account = opts[:cloud_account]
      cloud_account_graphs = Hash.new
      cloud_account_graphs[Graph::QUOTA_INSTANCES_IN_USE] = qos_failure_rate_graph(parent, opts = {})
      graphs[cloud_account] = cloud_account_graphs
    else
      ProviderAccount.all.each do |cloud_account|
        cloud_account_graphs = Hash.new
        cloud_account_graphs[Graph::QUOTA_INSTANCES_IN_USE] = quota_instances_in_use_graph(cloud_account,opts)
        graphs[cloud_account] = cloud_account_graphs
      end
    end
    graphs
  end

  def self.dashboard_quota_usage(user, opts = {})
    parent = opts[:parent]

    graphs = Hash.new
    graphs[parent] = quota_usage_graph(parent, opts)

    return graphs
  end

  def self.dashboard_qos_avg_time_to_submit_graph(user, opts = {})
    #FIXME add permission checks to filter what graphs user can get
    graphs = Hash.new

    #if a specific provider is given, just return that provider's graph.
    #otherwise return all graphs user has permission to see.
    if opts[:provider]
      provider = opts[:provider]
      provider_graphs = Hash.new
      provider_graphs[Graph::QOS_AVG_TIME_TO_SUBMIT] = qos_avg_time_to_submit_graph(provider,opts)
      graphs[provider] = provider_graphs
    else
      Provider.all.each do |provider|
        provider_graphs = Hash.new
        provider_graphs[Graph::QOS_AVG_TIME_TO_SUBMIT] = qos_avg_time_to_submit_graph(provider,opts)
        graphs[provider] = provider_graphs
      end
    end
    graphs
  end

  def self.dashboard_instances_by_provider (user,opts = {})
    #FIXME add permission checks to see if user can view this graph
    graphs = Hash.new
    graphs[Graph::INSTANCES_BY_PROVIDER_PIE] = instances_by_provider_pie(opts)
    graphs
  end

  private

  def self.quota_usage_graph (parent, opts = {})
    x = [1,2]

    #we'll just have zero values for the unexpected case where cloud_account has no quota
    y = x.collect { |v| 0 }
    if parent.quota
      quota = parent.quota
      data_point = DataServiceActiveRecord.quota_usage(parent, opts[:resource_name])
      #Handle No Limit case
      if data_point.max == Quota::NO_LIMIT
        y = [data_point.used, nil]
      else
        y = [data_point.used, data_point.max]
      end
    end

    chart_opts = {:x => x, :y => y}

    graphs = Hash.new
    graphs[Graph.get_quota_usage_graph_name(opts[:resource_name])] = draw_bar_chart(opts, chart_opts)
    return graphs
  end

  def self.qos_avg_time_to_submit_graph(parent, opts = {})
    start_time = Time.parse(opts[:start_time])
    end_time = Time.parse(opts[:end_time])
    interval_length = opts[:interval_length].to_f
    action = opts[:task_action]

    stats = DATA_SERVICE.qos_task_submission_stats(parent, start_time, end_time, interval_length, action)
    data = get_data_from_stats(stats, "average")
    draw_line_graph(opts, data)
  end

  def self.qos_failure_rate_graph(parent, opts = {})
    start_time = Time.parse(opts[:start_time])
    end_time = Time.parse(opts[:end_time])
    interval_length = opts[:interval_length].to_f
    failure_code = opts[:failure_code]

    stats = DATA_SERVICE.qos_failure_rate_stats(parent, start_time, end_time, interval_length, failure_code)
    data = get_data_from_stats(stats, "failure_rate")
    data[:y_range] = "[0:100]"
    draw_line_graph(opts, data)
  end

  def self.qos_avg_time_to_complete_life_cycle_event(parent, opts = {})
    start_time = Time.parse(opts[:start_time])
    end_time = Time.parse(opts[:end_time])
    interval_length = opts[:interval_length].to_f
    action = opts[:task_action]

    stats = DATA_SERVICE.qos_task_completion_stats(parent, start_time, end_time, interval_length, action)
    data = get_data_from_stats(stats, "average")
    draw_line_graph(opts, data)
  end

  def self.instances_by_provider_pie (opts = {})
    pie_opts = {}
    providers = Provider.all
    providers.each do |provider|
      running_instances = 0
      provider.provider_accounts.each do |account|
        running_instances += account.quota.running_instances
      end
      if running_instances > 0
        pie_opts[:"#{provider.name}"] = running_instances
      end
    end

    return draw_pie_chart(opts, pie_opts)
  end

  def self.get_data_from_stats(stats, type)
    x = []
    y = []
    y_max = 0
    for i in 0...stats.length do
      x << i
      y_value = stats[i][type]
      if y_value
        y << y_value
        if y_value > y_max
          y_max = y_value
        end
      else
        y << 0
      end
    end

    if y_max == 0
      y_max = 1
    else
      y_max = y_max * 1.1
    end

    y_range = "[0:" + y_max.to_s + "]"
    return { :x => x, :y => y, :y_range => y_range }
  end

  def self.draw_pie_chart(opts, pie_opts)
    #things we're checking for in opts: :height, :width
    height = 200 unless opts[:height].nil? ? nil : height = opts[:height].to_i
    width =  300 unless  opts[:width].nil? ? nil : width  = opts[:width].to_i

    graph = Graph.new
  end

  def self.draw_line_graph(opts, data)
    #things we're checking for in opts: :height, :width

    height = 60 unless opts[:height].nil? ? nil : height = opts[:height].to_i
    width = 100 unless  opts[:width].nil? ? nil : width  = opts[:width].to_i

    graph = Graph.new
    graph
  end

  def self.draw_bar_chart(opts, chart_opts)

    #things we're checking for in opts: :max_value, :height, :width

    unless max_value = opts[:max_value]
      max_value = 100 unless max_value = Quota.maximum('maximum_running_instances')
    end
    height = 80 unless opts[:height].nil? ? nil : height = opts[:height].to_i
    width = 150 unless  opts[:width].nil? ? nil : width  = opts[:width].to_i

    graph = Graph.new
  end

end
