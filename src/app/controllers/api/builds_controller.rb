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
  class BuildsController < ApplicationController
    respond_to :xml
    layout :false

    def index
      @builds = Aeolus::Image::ImageBuild.all
      respond_with(@builds)
    end

    def show
      id = params[:id]
      @build = Aeolus::Image::ImageBuild.find(id)
      p @build
      if @build
        respond_with(@build)
      else
        render :nothing => true, :status => 404
      end
    end
  end
end
