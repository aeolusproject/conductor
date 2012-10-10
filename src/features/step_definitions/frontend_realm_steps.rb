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
Given /there's no frontend realm/ do
  FrontendRealm.destroy_all
end

Given /^a frontend realm "([^"]*)" exists$/ do |realm_name|
  FrontendRealm.create(:name => realm_name)
end

Given /^a frontend realm "([^"]*)" exists mapped to a provider "([^"]*)"$/ do |realm_name, provider_name|
  @realm = FrontendRealm.find_or_create_by_name(:name => realm_name)
  @provider = FactoryGirl.create(:mock_provider, :name => provider_name)
  RealmBackendTarget.create!(:frontend_realm => @realm, :provider_realm_or_provider => @provider)
end

Given /^there is a frontend realm "([^"]*)"$/ do |name|
  FrontendRealm.find_by_name(name).should_not == nil
end

Given /^there are (\d+) frontend realms$/ do |number|
  FrontendRealm.count.should == number.to_i
end

When /^(?:|I )check "([^"]*)" frontend realm$/ do |realm_name|
  realm = FrontendRealm.find_by_name(realm_name)
  check("realm_checkbox_#{realm.id}")
end

Then /^there should be only (\d+) frontend realms$/ do |number|
  FrontendRealm.count.should == number.to_i
end

Given /^there is no provider$/ do
  Provider.destroy_all
end
