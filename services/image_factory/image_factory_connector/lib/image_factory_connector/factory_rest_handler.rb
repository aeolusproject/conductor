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

require 'base_handler'
require 'typhoeus'

class FactoryRestHandler < BaseHandler

  class EventData
    attr_accessor :event, :value, :obj, :uuid
    def initialize(args={})
      self.event = args[:event]
      self.value = args[:value].downcase
      self.obj = args[:obj]
      self.uuid = args[:uuid]
    end
  end

  def initialize(logger, conf)
    super(logger)
    config(conf)
  end

  def handle(data)
    super
  end

  def handle_status(data)
    # Steps:
    # 1. Take the data passed in, and split the addr into
    # object type and uuid
    e= _process_event(data)

    # 2. Call the conductor api with uuid and status
    hydra = Typhoeus::Hydra.new
    request = Typhoeus::Request.new(config[:conductor_url],
                                      :method  => :post,
                                      :timeout => 2000, # in milliseconds
                                      :headers => {:Accepts => "application/xml"},
                                      :params  => {:uuid => e.uuid, :status => e.value})
    hydra.queue(request)
    # FIXME: this is a temporary hack to get around the case where
    # updates are triggered before the initial request from conductor
    # has completed, which can happen because this is all asynchronous.
    # Once status is stored in warehouse rather than conductor, this
    # will not be an issue, so it is not worth doing something more
    # elegant right now.
    sleep(5)
    request.on_complete do |response|
      # 3. Log errors
      logger.debug "Return code is: #{response.code}"
      logger.debug "Return body is: #{response.body}"
    end
    hydra.run
  end

  def _process_event(data)
    addr = data["addr"]["_object_name"].split(':')
    e= EventData.new({:event=>data.event, :value=>data.new_status,
                      :obj=>addr[1], :uuid=>addr[2]})
    logger.debug "Data: #{e.inspect}"
    e
  end

  private

  def config(conf=nil)
    unless @config
      @config = YAML::load(File.open(conf))
    end
    return @config
  end
end
