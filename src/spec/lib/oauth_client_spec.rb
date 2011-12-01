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

require 'spec_helper'
require 'oauth_client'

describe OAuthClient do

  before(:each) do
    # Make sure this is initalized; we don't want test data in our global config
    SETTINGS_CONFIG[:oauth] ||= {}
  end

  it "should get authenticated resource with custom header" do
    # These are the proper configurations
    SETTINGS_CONFIG[:oauth]['http://example.com:5000/api'] = {
      :consumer_key => 'valid',
      :consumer_secret => 'good_secret'
    }
    client = OAuthClient.new('http://example.com:5000/api')
    consumer = client.instance_variable_get('@consumer')
    # We need to stub out sign! since it's otherwise unique on every request
    consumer.stub('sign!') do |request, *args|
      request['authorization'] = 'OAuth oauth_consumer_key="cloud_forms", oauth_nonce="ieQTc0gxyo6Z4PlQkgPvxdRCyvrtsLAVU9zfVdyDsnE", oauth_signature="u%2B9yniABqqpQgTAmQQJS5tNEv4g%3D", oauth_signature_method="HMAC-SHA1", oauth_timestamp="1317068969", oauth_version="1.0"'
      request['user-agent'] = 'OAuth gem v0.4.4'
    end
    response = client.get('/katello/api/organizations', {'katello-user' => 'admin'})
    response.code.should match("200")
  end

  it "should return a 401 for invalid credentials" do
    SETTINGS_CONFIG[:oauth]['http://example.com:5000/api'] = {
      :consumer_key => 'test',
      :consumer_secret => 'failure'
    }
    client = OAuthClient.new('http://example.com:5000/api')
    consumer = client.instance_variable_get('@consumer')
    consumer.stub('sign!') do |request, *args|
      request['authorization'] = 'OAuth oauth_consumer_key="test", oauth_nonce="zoT39JgdwI0fjqg9ZfJ2xN4QxyJyIghW7wWUHAxfY", oauth_signature="UFM87n9CcQXGsOUbHttPJs9NQOg%3D", oauth_signature_method="HMAC-SHA1", oauth_timestamp="1317068970", oauth_version="1.0"'
      request['user-agent'] = 'OAuth gem v0.4.4'
    end
    response = client.get('/katello/api/organizations', {'katello-user' => 'admin'})
    response.code.should match("401")
  end

end
