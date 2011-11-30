# == Schema Information
# Schema version: 20110517095823
#
# Table name: config_servers
#
#  id               :integer      not null, primary key
#  host             :string(255)  not null
#  port             :string(255)  not null
#  username         :string(255)  null
#  password         :string(255)  null
#  certificate      :string(255)  null
#  provider_id      :integer      not null, fk_provider
#

## Copyright (C) 2011 Red Hat, Inc.
## Written by Greg Blomquist <gblomqui@redhat.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; version 2 of the License.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
## MA  02110-1301, USA.  A copy of the GNU General Public License is
## also available at http://www.gnu.org/copyleft/gpl.html.
#

require 'cgi'
require 'oauth'

class ConfigServer < ActiveRecord::Base

  class ConnectionStatus
    attr_reader :state, :message
    def initialize
      @state = :untested
    end

    def untested?
      @state == :untested
    end

    def fail!(message)
      @state = :failure
      @message = message
    end
    def fail?
       @state == :failure
    end

    def success!(message=nil)
      @state = :success
      @message = message
    end
    def success?
      @state == :success
    end
  end
  @@status_fields = [:endpoint, :key, :secret]

  belongs_to :provider_account

  validates_presence_of :endpoint
  validates_presence_of :key
  validates_presence_of :secret
  validate :validate_connection

  API_VERSION = "1"

  # Reports the error message (if any) produced by testing the connection to
  # this config server.
  def connection_error_msg
    if not connection_valid?
      return status.message
    end
  end

  # Determines if the connection represented by #endpoint and authenticated
  # by oauth #key and #secret is a valid connection.  If the connection is
  # invalid, calling #connection_error_msg will return the error that was
  # generated when testing the connection.
  def connection_valid?
    if status.untested? or (changed? and (changes.keys & @@status_fields).empty?)
      begin
        test_connection
        status.success!
      rescue => e
        error_str = map_connection_exception_to_error(e)
        status.fail!(error_str)
      end
    end
    status.success?
  end

  def send_config(instance_config)
    url = "#{endpoint}/configs/#{API_VERSION}/#{instance_config.uuid}"
    args = get_connection_args(url, "post")
    data = CGI::escape(instance_config.to_s)
    args[:payload] = "data=#{data}"
    RestClient::Request.execute(args)
  end

  def delete_deployment_config(deployment_uuid)
    url = "#{endpoint}/deployment/#{API_VERSION}/#{deployment_uuid}"
    args = get_connection_args(url, "delete")
    begin
      RestClient::Request.execute(args)
    rescue RestClient::ResourceNotFound => e
      # allow for 404s, this means that the configs don't exist on this config
      # server
    end
  end

  private
  def status
    # smells like a factory in here
    @status ||= ConnectionStatus.new
  end

  def validate_connection
    # for validation hook
    if not connection_valid?
      errors.add(:base, status.message)
    end
  end

  def get_connection_args(url, method="get")
    args = {:method => method.to_sym}
    args[:url] = url
    # the :config_server_oauth parameter is inspected by one of the
    # RestClient#before_execution_procs that gets added in
    # config/initializers/config_server_oauth.rb.
    args[:config_server_oauth] = true
    args[:consumer_key] = key
    args[:consumer_secret] = secret
    args
  end

  # Test the connection to this config server.  Return nil on success, or throw
  # an exception on errors.  See
  # http://rubydoc.info/gems/rest-client/1.6.3/RestClient#STATUSES-constant
  # for more information on the types of exceptions.
  def test_connection
    args = get_connection_args("#{endpoint}/auth")
    args[:raw_response] = true
    RestClient::Request.execute(args)
  end

  def map_connection_exception_to_error(ex)
    if ex.kind_of?(RestClient::ExceptionWithResponse) or ex.kind_of?(RestClient::Exception) or ex.class == Errno::ETIMEDOUT
      error_string = I18n.translate("config_servers.errors.connection.generic_with_message", :url => endpoint, :msg => ex.message)
    elsif not ex.nil?
      error_string = I18n.translate("config_servers.errors.connection.generic", :url => endpoint)
    end
  end
end
