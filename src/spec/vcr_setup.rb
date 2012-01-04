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

require 'vcr'

VCR.config do |c|
  c.cassette_library_dir = 'spec/vcr/cassettes'
  c.stub_with :webmock
  # FIXME: This is necessary because the setup for each test will reset the database and
  # invoke db:seed, which triggers Solr to reindex the newly-created objects, which
  # is done over an HTTP request...
  c.allow_http_connections_when_no_cassette = true
end

# Mock all iwhd requests
Aeolus::Image::Warehouse::Connection.class_eval do
  def do_request(path = '', opts={})
    opts[:method]  ||= :get
    opts[:content] ||= ''
    opts[:plain]   ||= false
    opts[:headers] ||= {}
    result=nil
    VCR.use_cassette('iwhd_connection', :record => :new_episodes, :match_requests_on => [:method, :uri, :body]) do
      result = RestClient::Request.execute :method => opts[:method], :url => @uri + path, :payload => opts[:content], :headers => opts[:headers]
    end

    return Nokogiri::XML result unless opts[:plain]
    return result
  end
end

# Mock request for deployable xml
DeployableXML.class_eval do
  def self.import_xml_from_url(url)
    # Right now we allow this to raise exceptions on timeout / errors
    result = nil
    response = nil
    VCR.use_cassette('deployable_xml', :record => :new_episodes) do
      resource = RestClient::Resource.new(url, :open_timeout => 10, :timeout => 45)
      response = resource.get
    end
    if response.code == 200
      response
    else
      false
    end
  end
end

require 'oauth'
OAuth::AccessToken.class_eval do
  def request(method, path, *args)
    # By default, headers are ignored: https://www.relishapp.com/myronmarston/vcr/v/1-6-0/docs/cassettes/request-matching
    VCR.use_cassette('oauth', :record => :new_episodes, :match_requests_on => [:method, :uri, :body, :headers]) do
      super(method, path, *args)
    end
  end
end
