require 'spec_helper'

describe ConfigServer do
  describe "standard behavior" do
    before(:each) do
      @config_server = Factory.build :mock_config_server
    end

    it "should require an endpoint" do
      @config_server.should be_valid
      @config_server.endpoint = nil
      @config_server.should_not be_valid
    end

    it "should require a key" do
      @config_server.should be_valid
      @config_server.key = nil
      @config_server.should_not be_valid
    end

    it "should require a secret" do
      @config_server.should be_valid
      @config_server.secret = nil
      @config_server.should_not be_valid
    end
  end

  describe "error behavior: invalid credentials" do
    before(:each) do
      @config_server = Factory.build :invalid_credentials_config_server
    end

    it "should report an error when unauthorized" do
      @config_server.should_not be_valid
      @config_server.errors.full_messages.join(" ").should include("Could not validate config server connection")
    end
  end
end
