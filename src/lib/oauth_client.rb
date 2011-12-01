#
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
#
class OAuthClient
  require 'oauth'

  def initialize(resource)
    @consumer = OAuth::Consumer.new(
      consumer_key_for_resource(resource),
      consumer_secret_for_resource(resource),
      :site => resource
    )
    @access_token = OAuth::AccessToken.new(@consumer)
  end

  def delete(uri, headers=nil)
    headers ||= default_headers
    @access_token.delete(uri, headers)
  end

  def get(uri, headers=nil)
    headers ||= default_headers
    @access_token.get(uri, headers)
  end

  def head(uri, headers=nil)
    headers ||= default_headers
    @access_token.head(uri, headers)
  end

  def post(uri, body='', headers=nil)
    headers ||= default_headers
    @access_token.post(uri, body, headers)
  end

  def put(uri, body='', headers=nil)
    headers ||= default_headers
    @access_token.put(uri, body, headers)
  end

  private

  # Default headers - override in specific clients
  def default_headers
    nil
  end

  def consumer_key_for_resource(resource)
    @consumer_key ||= consumer_credentials_for_resource(resource)[:consumer_key]
  end

  def consumer_secret_for_resource(resource)
    @consumer_secret ||= consumer_credentials_for_resource(resource)[:consumer_secret]
  end

  def consumer_credentials_for_resource(resource)
    begin
      SETTINGS_CONFIG[:oauth][resource].reject{|k,v| ![:consumer_key, :consumer_secret].include?(k) }
    rescue
      raise "No credentials found in settings.yml for provider #{resource}"
    end
  end

end
