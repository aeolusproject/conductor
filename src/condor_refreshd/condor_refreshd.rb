#!/usr/bin/env ruby

# Copyright (C) 2010 Red Hat, Inc.
# Written by Chris Lalancette <clalance@redhat.com>
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

$: << File.join(File.dirname(__FILE__), "../dutils")
$: << File.join(File.dirname(__FILE__), "../config")

require 'rubygems'
require 'optparse'
require 'socket'
require 'dutils'

port = 7890
help = false

optparse = OptionParser.new do |opts|

opts.banner = <<BANNER
Usage:
condor_refreshd [options]

Options:
BANNER
  opts.on( '-p', '--port PORT', 'Use PORT (default: 7890)') do |newport|
    port = newport
  end
  opts.on( '-h', '--help', '') { help = true }
end

optparse.parse!

if help
  puts optparse
  exit(0)
end

socket = UDPSocket.new
socket.bind(nil, port)
while true
  packet = socket.recvfrom(1024)
  puts "Doing classad sync"
  condormatic_classads_sync
end
