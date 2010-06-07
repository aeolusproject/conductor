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
  layout :layout
  before_filter :require_user

  def layout
    return "dashboard" unless ajax?
  end

  def ajax?
    return params[:ajax] == "true"
  end

  def provider_qos_graph(opts = {})
    entity = nil
    params[:provider] = Provider.find(params[:id])
    graph = GraphService.dashboard_qos(current_user, params)[params[:provider]][Graph::QOS_AVG_TIME_TO_SUBMIT]
    respond_to do |format|
      format.svg  { render :xml => graph.svg}
    end
  end

  def account_quota_graph(opts = {})
    entity = nil
    params[:account] = CloudAccount.find(params[:id])
    graph = GraphService.dashboard_quota(current_user, params)[params[:account]][Graph::QUOTA_INSTANCES_IN_USE]
    respond_to do |format|
      format.svg  { render :xml => graph.svg}
    end
  end

  def index
    # FIXME filter to just those that the user has access to
    @providers = Provider.find(:all)
    @cloud_accounts = CloudAccount.find(:all)
    @pools = Pool.find(:all)

    # FIXME remove general role based permission check, replace w/
    # more granular / per-permission-object permission checks on the
    # dashboard in the future (here and in dashboard views)
    @is_admin = @current_user.permissions.collect { |p| p.role }.
                              find { |r| r.name == "Administrator" }

    @hide_getting_started = cookies["#{@current_user.login}_hide_getting_started"]
    @current_users_pool = Pool.find(:first, :conditions => ['name = ?', @current_user.login])
    @cloud_accounts = CloudAccount.list_for_user(@current_user, Privilege::ACCOUNT_VIEW)
    @stats = Instance.get_user_instances_stats(@current_user)
    render :action => :summary
  end

  def hide_getting_started
    cookies["#{@current_user.login}_hide_getting_started"] = { :value => true, :expires => 1.year.from_now }
    redirect_to :action => 'show'
  end

end
