#
# Copyright (C) 2011 Red Hat, Inc.
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
