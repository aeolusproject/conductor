#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


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
      error_str = nil
      begin
        response = test_connection
        if "200" == response.code
          status.success!
        else
          error_str = map_response_to_error(response)
        end
      rescue => exception
        error_str = map_exception_to_error(exception)
      end
      status.fail!(error_str) if error_str
    end
    status.success?
  end

  def send_config(instance_config)
    uri = "/configs/#{API_VERSION}/#{instance_config.uuid}"
    body = {:data => instance_config.to_s}
    oauth.post(uri, body)
  end

  def delete_deployment_config(deployment_uuid)
    uri = "/deployment/#{API_VERSION}/#{deployment_uuid}"
    oauth.delete(uri)
  end

  private
  def status
    # smells like a factory in here
    @status ||= ConnectionStatus.new
  end

  def validate_connection
    # for validation hook
    endpoint.chomp! '/' unless endpoint.nil?
    if not connection_valid?
      errors.add(:base, status.message)
    end
  end

  def consumer
    OAuth::Consumer.new(key, secret, :site => endpoint)
  end

  def oauth
    OAuth::AccessToken.new(consumer)
  end

  # Test the connection to this config server.
  # Return the http response
  def test_connection
    oauth.get("/auth")
  end

  def map_response_to_error(response)
    msg = "#{response.code}: #{response.message}"
    error_string = I18n.translate("config_servers.errors.connection.generic_with_message", :url => endpoint, :msg => msg)
  end

  def map_exception_to_error(exception)
    if [Errno::ETIMEDOUT, Errno::ECONNREFUSED].include? exception.class
      error_string = I18n.translate("config_servers.errors.connection.generic_with_message", :url => endpoint, :msg => exception.message)
    else
      error_string = I18n.translate("config_servers.errors.connection.generic", :url => endpoint)
    end
  end
end
