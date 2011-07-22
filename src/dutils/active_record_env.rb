#
# Copyright (C) 2008 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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

$: << File.join(File.dirname(__FILE__), "../app")

require 'rubygems'

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

ENV['RAILS_ENV'] = 'development' unless ENV['RAILS_ENV']

require File.dirname(__FILE__) + '/../config/boot'
require File.dirname(__FILE__) + '/../config/environment'

def database_connect
  conf = YAML::load(File.open(File.dirname(__FILE__) + '/../config/database.yml'))
  ActiveRecord::Base.establish_connection(conf[ENV['RAILS_ENV']])
end

# Open ActiveRecord connection
database_connect
