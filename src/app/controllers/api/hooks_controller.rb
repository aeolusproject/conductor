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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Api
  class HooksController < ApplicationController
    before_filter :require_user_api
    rescue_from ActiveRecord::RecordNotFound, :with => :not_found

    respond_to :xml
    layout :false

    def index
      @hooks = Hook.all
      respond_with(@hooks)
    end

    def show
      @hook = Hook.find(params[:id])
      respond_with(@hook)
    end

    def create
      unless params[:hook]
        head :status => 400 and return
      end

      version = params[:hook][:version]
      unless version == '1'
        head :status => 501 and return
      end

      @hook = Hook.new params[:hook]
      if @hook.save
        render 'show', :status => :created, :location => api_hook_url(@hook)
      else
        head :status => 400
      end
    end

    def destroy
      hook = Hook.find(params[:id])

      if hook.destroy
        head :status => 204
      else
        head :status => 500
      end
    end

    private
    def not_found
      head :status => :not_found
    end

  end
end
