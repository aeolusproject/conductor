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

# The :config_server_oauth parameter is added in the config_server model object
# just before executing each request against a config server.
# This is a little scary, since this proc is added at the global RestClient
# scope.  The :config_server_oauth parameter should keep any other RestClient
# library users from having this block accidentally executed.
#
RestClient.add_before_execution_proc do |request, params|
  if params.key?(:config_server_oauth)
    consumer = OAuth::Consumer.new(
      params[:consumer_key],
      params[:consumer_secret],
      :site => params[:url]
    )
    access_token = OAuth::AccessToken.new(consumer)
    access_token.sign!(request)
  end
end
