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

require 'logger'

class BaseHandler

  def initialize(logger=nil)
    logger(logger)
  end

  def handle(data)
    logger.debug "====== Type of event: #{data.event}"
    #puts "should be calling the logger now..."
    if data.event == 'STATUS'
      handle_status(data)
    elsif data.event == 'FAILURE'
      handle_failed(data)
    end
  end

  def handle_status(data)
    logger.debug "{data.event}, #{data.new_status}"
  end

  def handle_failed(data)
    logger.error "#{data.to_s}"
  end

  private
  def logger(logger=nil)
    @logger ||= logger
    unless @logger
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::ERROR
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    end
    return @logger
  end
end
