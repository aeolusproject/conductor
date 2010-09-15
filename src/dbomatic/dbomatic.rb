# Copyright (C) 2010 Red Hat, Inc.
# Written by Mohammed Morsi <mmorsi@redhat.com>
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
require 'dutils'
require 'nokogiri'
require 'rb-inotify'
require 'optparse'

help = false

condor_event_log_dir    =   "/var/log/condor"
dbomatic_run_dir        =   "/var/run/dbomatic"

optparse = OptionParser.new do |opts|

opts.banner = <<BANNER
Usage:
dbomatic [options]

Options:
BANNER
  opts.on( '-p', '--path PATH', 'Use PATH to the condor log directory') do |newpath|
    condor_event_log_dir = newpath
  end
  opts.on( '-r', '--run PATH', 'Use PATH to the dbomatic runtime directory') do |newpath|
    dbomatic_run_dir = newpath
  end
  opts.on( '-h', '--help', '') { help = true }
end

begin
optparse.parse!
rescue OptionParser::InvalidOption => e
  puts e
  puts optparse
  exit(1)
end

if help
  puts optparse
  exit(0)
end

CONDOR_EVENT_LOG_FILE   =   "#{condor_event_log_dir}/EventLog"
EVENT_LOG_POS_FILE      =   "#{dbomatic_run_dir}/event_log_position"

# Handle the event log's xml
class CondorEventLog < Nokogiri::XML::SAX::Document
  attr_accessor :tag, :event_type, :event_cmd, :event_time

  # Store the name of the event log attribute we're looking at
  def start_element(element, attributes)
    @tag = attributes[1] if element == "a"
  end

  # Store the value of the event log attribute we're looking at
  def characters(string)
    unless string.strip == ""
      if @tag == "MyType"
        @event_type = string
      elsif @tag == "Cmd"
        @event_cmd = string
      elsif @tag == "EventTime"
        @event_time = string
      end
    end
  end

  # Create a new entry for events which we have all the neccessary data for
  def end_element(element)
    if element == "c" && !@event_cmd.nil?
      # Condor may write to event log before condormatic returns and instance
      # table is updated. Extract instance name from event_cmd and query on that
      inst_name = @event_cmd[4,@event_cmd.size-4].gsub(/_[0-9]*$/, '')
      inst = Instance.find(:first, :conditions => ['name = ?', inst_name])
      puts "Instance event #{inst.name} #{@event_type} #{@event_time}"
      InstanceEvent.create! :instance => inst,
                            :event_type => @event_type,
                            :event_time => @event_time
      @tag = @event_type = @event_cmd = @event_time = nil
    end
  end
end
parser = Nokogiri::XML::SAX::PushParser.new(CondorEventLog.new)

# XXX hack, condor event log doesn't seem to have a top level element
# enclosing everything else in the doc (as standards conforming xml must).
# Create one for parsing purposes.
parser << "<events>"

def parse_log_file(log_file, parser)
  while s = log_file.gets
    parser << s
  end
  File.open(EVENT_LOG_POS_FILE, 'w') { |f| f.write log_file.pos.to_s }
end

notifier = INotify::Notifier.new
log_file = nil

if File.exists? CONDOR_EVENT_LOG_FILE
  log_file = File.open(CONDOR_EVENT_LOG_FILE)

  # persistantly store log position in filesystem
  # incase of dbomatic restarts
  if File.exists?(EVENT_LOG_POS_FILE)
    File.open(EVENT_LOG_POS_FILE, 'r') { |f| log_file.pos = f.read.to_i }
  end

  # Setup inotify watch for condor event log
  notifier.watch(CONDOR_EVENT_LOG_FILE, :modify){ |event|
    parse_log_file log_file, parser
  }

# if log file doesn't exist wait until it does
else
  notifier.watch(condor_event_log_dir, :create){ |event|
    if event.name == "EventLog"
      log_file = File.open(CONDOR_EVENT_LOG_FILE)
      parse_log_file log_file, parser

      # Setup inotify watch for condor event log
      notifier.watch(CONDOR_EVENT_LOG_FILE, :modify){ |event|
        parse_log_file log_file, parser
      }
    end
  }
end

notifier.run

parser << "</events>"
parser.finish
