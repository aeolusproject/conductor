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
require_relative '../../spec/spec_helper'

Given /^I want to add a new config server$/ do
  c = Factory.build(:mock_config_server)
  ConfigServer.stub!(:new).and_return(c)
end

Given /^I am not sure about the config server endpoint$/ do
  c = Factory.build(:invalid_endpoint_config_server)
  ConfigServer.stub!(:new).and_return(c)
end

Given /^I am not sure about the config server credentials$/ do
  c = Factory.build(:invalid_credentials_config_server)
  ConfigServer.stub!(:new).and_return(c)
end

Given /^there is a mock config server "(http|https):\/\/(.*)" for account "(.*)"$/ do |scheme,endpoint,acc|
  provider = Provider.find_by_name "mock"
  provider ||= Factory :mock_provider, :name => "mock"
  mock_account = ProviderAccount.find_by_label(acc)
  mock_account ||= Factory :mock_provider_account, :label => acc, :provider => provider
  params = {:endpoint => endpoint, :key => "key", :secret => "secret", :provider_account => mock_account}

  @config_server = Factory :mock_config_server, params
  # Don't particularly like this next bit, but the problem is the "create"
  # default_strategy used when instantiating the Factory leaves the
  # @config_server in a "SUCCESS" status.  This bit effectively "resets" the
  # status to "UNTESTED" so the :test_connection method(stub) has to get called
  @config_server.stub!(:status).and_return(ConfigServer::ConnectionStatus.new())
  case endpoint
    when "bad_credentials"
      response = FakeResponse.new("401", "Unauthorized")
      @config_server.stub!(:test_connection).and_return(response)
    when "bad_host"
      @config_server.stub!(:test_connection).and_raise(Errno::ETIMEDOUT)
  end
  # ensure that the :mock_config_server (with stubbed methods) is returned
  ConfigServer.stub!(:find).and_return(@config_server)
end
