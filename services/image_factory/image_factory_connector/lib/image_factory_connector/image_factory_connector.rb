#
# Copyright (C) 2011 Red Hat, Inc.
# Written by Jason Guiditta <jguiditt@redhat.com>
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

require 'sinatra/base'
require 'builder'
require 'image_factory'
require 'factory_rest_handler'

class ImageFactoryConnector < Sinatra::Base
  configure do
    set :logging, true
    set :server, %w[thin mongrel webrick]
    set :port, 2003
    set :app_file, __FILE__
    set :views, File.dirname(__FILE__) + '/views'
    @console = ImageFactoryConsole.new({:handler=>FactoryRestHandler.new})
    @console.start
    set :console, @console
  end

  # TODO: add validation for required params not being passed at all,
  # not just checking for blank.  IOW, define list of expected params
  # somewhere and fail if the key is missing (as well as if value is missing)
  def validate
    @error={}
    params.each do |k,v|
      if v.empty?
        @error[k] = "Missing #{k}"
      end
    end
    if @error!={}
      halt builder :error
    end
  end

  before do
    validate
  end

  get "/" do
     "#{settings.console.q}"
  end

  post "/build" do
    @b=settings.console.build_image("#{params[:template]}", "#{params[:target]}")
    builder :image
  end

  post "/push" do
    @b=settings.console.push_image("#{params[:image_id]}", "#{params[:provider]}", "#{params[:credentials]}")
    builder :image
  end

  get "/shutdown" do
    settings.console.shutdown
    "Console connection closed"
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
