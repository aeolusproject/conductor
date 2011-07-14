require 'spec_helper'

describe ConfigServer do
  describe "standard behavior" do
    before(:each) do
      @config_server = Factory.build :mock_config_server
    end

    it "should require a host" do
      @config_server.should be_valid
      @config_server.host = nil
      @config_server.should_not be_valid
    end

    it "should require a port" do
      @config_server.should be_valid
      @config_server.port = nil
      @config_server.should_not be_valid
    end

    it "should suggest https when a cert is present" do
      @config_server.certificate = "abc"
      @config_server.base_url.should =~ /https:\/\/.*/
    end

    it "should suggest http when a cert is not present" do
      @config_server.certificate = nil
      @config_server.base_url.should =~ /http:\/\/.*/
    end
  end

  describe "error behavior: invalid credentials" do
    before(:each) do
      @config_server = Factory.build :invalid_credentials_config_server
    end

    it "should report an error when unauthorized" do
      @config_server.should_not be_valid
      @config_server.errors.full_messages.join(" ").should include_text("Could not validate config server connection")
    end
  end
end
