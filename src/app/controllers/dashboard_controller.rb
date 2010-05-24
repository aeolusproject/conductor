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

  def index
    @hide_getting_started = cookies["#{@current_user.login}_hide_getting_started"]
    @current_users_pool = Pool.find(:first, :conditions => ['name = ?', @current_user.login])
    render :action => :summary
  end

  def hide_getting_started
    cookies["#{@current_user.login}_hide_getting_started"] = { :value => true, :expires => 1.year.from_now }
    redirect_to :action => 'show'
  end

end
