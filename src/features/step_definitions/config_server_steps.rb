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
  provider = Factory :mock_provider, :name => "mockprovider"
  mock_account = Factory :mock_provider_account, :label => acc, :provider => provider
  params = {:endpoint => endpoint, :key => "key", :secret => "secret", :provider_account => mock_account}

  @config_server = Factory :mock_config_server, params
  # Don't particularly like this next bit, but the problem is the "create"
  # default_strategy used when instantiating the Factory leaves the
  # @config_server in a "SUCCESS" status.  This bit effectively "resets" the
  # status to "UNTESTED" so the :test_connection method(stub) has to get called
  @config_server.stub!(:status).and_return(ConfigServer::ConnectionStatus.new())
  case endpoint
    when "bad_credentials"
      @config_server.stub!(:test_connection).and_raise(RestClient::Unauthorized)
    when "bad_host"
      @config_server.stub!(:test_connection).and_raise(Errno::ETIMEDOUT)
  end
  # ensure that the :mock_config_server (with stubbed methods) is returned
  ConfigServer.stub!(:find).and_return(@config_server)
end
