#
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class DashboardController < ApplicationController
  before_filter :require_user
  before_filter :get_nav_items, :only => [:index]

  def ajax?
    return params[:ajax] == "true"
  end

  def section_id
    'operation'
  end

  def provider_qos_avg_time_to_submit_graph
    params[:provider] = Provider.find(params[:id])
    graph = GraphService.dashboard_qos_avg_time_to_submit_graph(current_user, params)[params[:provider]][Graph::QOS_AVG_TIME_TO_SUBMIT]
    respond_to do |format|
      format.svg  { render :xml => graph.svg}
    end
  end

  def quota_usage_graph
    if params[:cloud_account_id]
      params[:parent] = CloudAccount.find(params[:cloud_account_id])
    elsif params[:pool_id]
      params[:parent] = Pool.find(params[:pool_id])
    else
      return nil
    end

    graphs = GraphService.dashboard_quota_usage(current_user, params)
    graph = graphs[params[:parent]][Graph.get_quota_usage_graph_name(params[:resource_name])]
    respond_to do |format|
      format.svg  { render :xml => graph.svg}
    end
  end

  def provider_instances_graph
    graph = GraphService.dashboard_instances_by_provider(current_user, params)[Graph::INSTANCES_BY_PROVIDER_PIE]
    respond_to do |format|
      format.svg  { render :xml => graph.svg}
    end
  end

  def monitor
  end

  def index
    # FIXME filter to just those that the user has access to
    @cloud_accounts = CloudAccount.find(:all)


    render :action => 'monitor'
  end

  def hide_getting_started
    cookies["#{@current_user.login}_hide_getting_started"] = { :value => true, :expires => 1.year.from_now }
    redirect_to :action => 'show'
  end

end
