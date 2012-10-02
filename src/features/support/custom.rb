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
#Seed the DB with fixture data

include Warden::Test::Helpers
Warden.test_mode!
# We can't stub out these methods properly in cucumber, and we don't want to
# couple these tests to require the core server be running (connections should be tested
# in the client code), so override the methods for tests here.
Provider.class_eval do
  def valid_framework?
    true
  end

  def valid_provider?
    true
  end

  def populate_realms
    true
  end
end

ProviderAccount.class_eval do

  def valid_credentials?
    credentials_hash['username'].to_s == 'mockuser' && credentials_hash['password'].to_s == 'mockpassword'
  end

#  def instance_key
#    @key = mock('Key').as_null_object
#    @key.stub!(:pem).and_return("PEM")
#    @key.stub!(:id).and_return("1_user")
#    @key
#  end
end

Deployment.class_eval do
  def condormatic_instance_create(task)
    true
  end
end

InstanceKey.class_eval do
  def replace_on_server(addr, new)
    true
  end
end

# for cucumber tests we want to authenticate against local db,
# not LDAP
User.class_eval do
  class << self
    SETTINGS_CONFIG[:auth][:strategy] = "database"
    alias authenticate_using_ldap authenticate
  end
end
