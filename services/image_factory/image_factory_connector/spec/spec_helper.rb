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
ENV['RACK_ENV'] = 'test'
ENV["CONNECTOR_CONFIG"] = "#{File.dirname(__FILE__)}/../lib/conf/aeolus_connector.yml"
$: << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))
require 'rubygems'
#require 'sinatra/base'
require 'image_factory_connector'
require 'rack/test'

Spec::Runner.configure do |conf|
  conf.include(Rack::Test::Methods)
end