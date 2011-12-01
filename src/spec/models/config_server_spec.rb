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
