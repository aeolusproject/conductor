#!/usr/bin/ruby
#
# Copyright (C) 2008 Red Hat, Inc.
# Written by Chris Lalancette <clalance@redhat.com> and
# Ian Main <imain@redhat.com>
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
$: << File.join(File.dirname(__FILE__), ".")

require 'rubygems'
require 'monitor'
require 'dutils'
require 'optparse'
require 'daemons'
require 'logger'
include Daemonize

require 'taskomatic_instance'

# This sad and pathetic readjustment to ruby logger class is
# required to fix the formatting because rails does the same
# thing but overrides it to just the message.
#
# See eg: http://osdir.com/ml/lang.ruby.rails.core/2007-01/msg00082.html
#
class Logger
  def format_message(severity, timestamp, progname, msg)
    "#{severity} #{timestamp} (#{$$}) #{msg}\n"
  end
end

class TaskOmatic

  include MonitorMixin

  $logfile = '/var/log/deltacloud-portal/taskomatic.log'

  def initialize()
    super()

    @sleeptime = 5
    @nth_host = 0

    do_daemon = true
    do_debug = false

    opts = OptionParser.new do |opts|
      opts.on("-h", "--help", "Print help message") do
        puts opts
        exit
      end
      opts.on("-n", "--nodaemon", "Run interactively (useful for debugging)") do |n|
        do_daemon = false
      end
      opts.on("-d", "--debug", "Print verbose debugging output") do |d|
        do_debug = true
      end
      opts.on("-s N", Integer, "--sleep",
              "Seconds to sleep between iterations (default is 5 seconds)") do |s|
        sleeptime = s
      end
    end
    begin
      opts.parse!(ARGV)
    rescue OptionParser::InvalidOption
      puts opts
      exit
    end

    if do_daemon
      # This gets around a problem with paths for the database stuff.
      # Normally daemonize would chdir to / but the paths for the database
      # stuff are relative so it breaks it.. It's either this or rearrange
      # things so the db stuff is included after daemonizing.
      pwd = Dir.pwd
      daemonize
      Dir.chdir(pwd)
      @logger = Logger.new($logfile)
    else
      @logger = Logger.new(STDERR)
    end

    #@logger.level = Logger::DEBUG if do_debug
    #
    # For now I'm going to always enable debugging until we do a real release.
    @logger.level = Logger::DEBUG
  end

  def mainloop()

    loop do
      tasks = Array.new
      begin
        tasks = Task.find(:all, :conditions =>
                          [ "state = ?", Task::STATE_QUEUED ])
      rescue => ex
        @logger.error "1 #{ex.class}: #{ex.message}"
        if Task.connected?
          begin
            ActiveRecord::Base.connection.reconnect!
          rescue => norecon
            @logger.error "2 #{norecon.class}: #{norecon.message}"
          end
        else
          begin
            database_connect
          rescue => ex
            @logger.error "3 #{ex.class}: #{ex.message}"
          end
        end
      end

      tasks.each do |task|

        task.time_started = Time.now

        state = Task::STATE_FINISHED
        begin
          case task.action
            when InstanceTask::ACTION_CREATE
              tasko_task = TaskomaticInstanceCreate.new(@logger, task)
            when InstanceTask::ACTION_START
              tasko_task = TaskomaticInstanceStart.new(@logger, task)
            when InstanceTask::ACTION_STOP
              tasko_task = TaskomaticInstanceStop.new(@logger, task)
            when InstanceTask::ACTION_REBOOT
              tasko_task = TaskomaticInstanceReboot.new(@logger, task)
            when InstanceTask::ACTION_DESTROY
              tasko_task = TaskomaticInstanceDestroy.new(@logger, task)
          else
            @logger.error "unknown task " + task.action
            state = Task::STATE_FAILED
            task.message = "Unknown task type"
          end

        # Implement the task.. this may be done in threads based on
        # dependencies in the future.
        tasko_task.run

        rescue Exception => ex
          @logger.error "Task action processing failed: #{ex.class}: #{ex.message}"
          @logger.error ex.backtrace
          state = Task::STATE_FAILED
          task.message = ex.message
        end

        task.state = state
        task.time_ended = Time.now
        begin
          task.save!
        rescue Exception => ex
          @logger.error "Error saving task state for task #{task.id}: #{ex.class}: #{ex.message}"
          @logger.error ex.backtrace
        end
        @logger.info "done"
      end
      # FIXME: here, we clean up "orphaned" tasks.  These are tasks
      # that we had to orphan (set task_target to nil) because we were
      # deleting the object they depended on.
      Task.find(:all, :conditions =>
                [ "task_target_id IS NULL and task_target_type IS NULL" ]).each do |task|
        task.destroy
      end
      sleep(@sleeptime)
    end
  end
end

taskomatic = TaskOmatic.new()
taskomatic.mainloop()
