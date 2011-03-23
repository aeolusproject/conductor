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

# TODO: figure out what I am doing wrong here that I need this line
$: << File.expand_path(File.join(File.dirname(__FILE__), "."))
require 'cqpid'
require 'qmf2'
require 'logger'
require 'base_handler'

class ImageFactoryConsole < Qmf2::ConsoleHandler

  attr_accessor :q, :handler

  def initialize(args={})
#    @retry_limit = args.include?(:retry_limit) ? args[:retry_limit] : 20
#    @delay = args.include?(:delay) ? args[:delay] : 15
    host = args.include?(:host) ? args[:host] : "localhost"
    port = args.include?(:port) ? args[:port] : 5672
#   url = "amqp://#{host}:#{port}" <- the amqp part here doesnt work yet
    url = "#{host}:#{port}"
    opts = {"reconnect"=>"true"}
    @connection = Cqpid::Connection.new(url, opts)
    @connection.open
    @session = Qmf2::ConsoleSession.new(@connection)
    @session.open
    @session.set_agent_filter("[and, [eq, _vendor, [quote, 'redhat.com']], [eq, _product, [quote, 'imagefactory']]]")

    if args.include?(:logger)
      @logger = args[:logger]
    else
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::ERROR
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
    end
    @handler = args.include?(:handler)? args[:handler]: BaseHandler.new
    super(@session)
  end

  # Call this method to initiate a build, and get back an
  # BuildAdaptor object.
  # * descriptor => String
  # This can be either xml or a url pointing to the xml
  # * target => String
  # Represents the target provider type to build for (ec2, mock, etc)
  # * Returns => a BuildAdaptor object
  #
  def build_image(descriptor, target)
    # TODO: return error if there is a problem calling this method or getting
    # a factory instance
    response = factory.image(descriptor, target)
    build_adaptor(response)
  end

  # Call this method to push an image to a provider, and get back an
  # BuildAdaptor object.
  # * image_id => String (uuid)
  # * provider => String
  # Represents the target provider to build for (ec2-us-east, mock, etc)
  # * credentials => String
  # XML block to be used for registration, upload, etc
  # * Returns => a BuildAdaptor object
  #
  def push_image(image_id, provider, credentials)
    # TODO: return error if there is a problem calling this method or getting
    # a factory instance
    response = factory.provider_image(image_id, provider, credentials)
    build_adaptor(response)
  end

  #TODO: enhance both of these methods to handle multiple agents
  def agent_added(agent)
    @logger.debug "GOT AN AGENT:  #{agent} at #{Time.now.utc}"
    @q = agent if agent.product == "imagefactory"
  end

  def agent_deleted(agent, reason)
    @logger.debug "AGENT GONE:  #{agent} at #{Time.now.utc}, because #{reason}"
    unless @q==nil
        @q = {} if @q.product == agent.product
    end
  end

  # TODO: handle agent restart events (this will be more useful when
  # restarted agent can recover an in-process build
  def agent_restarted(agent)
    @logger.debug "AGENT RESTARTED:  #{agent.product}"
  end

  # TODO: handle schema updates.  This will be more useful when/if
  # we make this a more generic console to talk to different agents.
  def agent_schema_updated(agent)
    @logger.debug "AGENT SCHEMA UPDATED:  #{agent.product}"
  end

  def event_raised(agent, data, timestamp, severity)
    @logger.debug "GOT AN EVENT:  #{agent}, #{data} at #{timestamp}"
    @handler.handle(data)
  end

  def shutdown
    @logger.debug "Closing connections.."
    if @session
      @session.close
    end
    @connection.close
    self.cancel
  end

  private

  def factory
    @factory ||= @q.query("{class:ImageFactory, package:'com.redhat.imagefactory'}").first
  end

  def build_adaptor(response)
    imgfacaddr = Qmf2::DataAddr.new(response['build_adaptor'])
    query = Qmf2::Query.new(imgfacaddr)
    @q.query(query).first
  end

end

#i = ImageBuilderConsole.new
#i.run
