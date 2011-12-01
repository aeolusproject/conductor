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
def mock_instance
  @mock_instance ||= FactoryGirl.create :mock_running_instance
end

def pending_instance
  @pending_instance ||= FactoryGirl.create :mock_pending_instance
end

Given /^a mock running instance exists$/ do
  mock_instance.instance_key = FactoryGirl.create :mock_instance_key, :instance => mock_instance
end

Given /^a mock pending instance exists$/ do
  pending_instance
end

Given /^I am viewing the mock instance detail$/ do
  visit instance_url(mock_instance)
end

Given /^the instance "([^"]*)" is in the (\w*) state$/ do |instance, state|
  instance = Instance.find_by_name(instance)
  instance.state = state
  instance.save!
end

When /^I am viewing the pending instance detail$/ do
  visit instance_url(pending_instance)
end

When /^I am viewing the mock instance$/ do
  visit instance_url(mock_instance)
end

When /^I manually go to the key action for this instance$/ do
  visit key_instance_url(pending_instance)
end

Given /^I see "([^"]*)"$/ do |text|
  page.should have_content(text)
end

Then /^I should see the Save dialog for a (.+) file$/ do |filetype|
  page.response_headers["Content-Disposition"].should
  match(/^attachment;\sfilename=.*#{filetype}$/)
end

Given /^there is a "([^"]*)" instance$/ do |name|
  FactoryGirl.create :instance, :name => name
end

Given /^there is a "([^"]*)" failed instance$/ do |name|
  FactoryGirl.create :instance, :name => name, :state => Instance::STATE_ERROR
end

Given /^there is a "([^"]*)" running instance$/ do |name|
  FactoryGirl.create :instance, :name => name, :state => Instance::STATE_RUNNING
end

Given /^there is a "([^"]*)" stopped instance$/ do |name|
  FactoryGirl.create :instance, :name => name, :state => Instance::STATE_STOPPED
end

Given /^there is "([^"]*)" conductor hardware profile$/ do |name|
  FactoryGirl.create :front_hwp1, :name => name
end

Given /^there is "([^"]*)" frontend realm$/ do |name|
  FactoryGirl.create :frontend_realm, :name => name
end

Given /^there is "([^"]*)" pool$/ do |arg1|
  FactoryGirl.create :pool, :name => arg1
end


When /^I check "([^"]*)" instance$/ do |name|
  inst = Instance.find_by_name(name)
  check("instance_checkbox_#{inst.id}")
end

Given /^there are the following instances:$/ do |table|
  table.hashes.each do |hash|
    FactoryGirl.create(:instance, :name => hash['name'],
                       :external_key => hash['external_key'],
                       :state => hash['state'],
                       :public_addresses => hash['public_addresses'],
                       :private_addresses => hash['private_addresses'])
  end
end

Given /^there is the following instance with a differently-named owning user:$/ do |table|
  table.hashes.each do |hash|
    FactoryGirl.create(:other_owner_instance, :name => hash['name'],
                       :external_key => hash['external_key'],
                       :state => hash['state'],
                       :public_addresses => hash['public_addresses'],
                       :private_addresses => hash['private_addresses'])
  end
end


Given /^there are (\d+) instances$/ do |count|
  Instance.all.each {|i| i.destroy}
  count.to_i.times do |i|
    FactoryGirl.create :mock_pending_instance, :name => "inst#{i}"
  end
end

Given /^I accept JSON$/ do
  page.driver.header 'Accept', 'application/json'
  header 'Accept', 'application/json'
end

Given /^I request XHR$/ do
  page.driver.header 'accept', 'application/javascript'
  page.driver.header 'X-Requested-With', 'XMLHttpRequest'
end

Then /^I should see (\d+) instances in JSON format$/ do |count|
  ActiveSupport::JSON.decode(page.source).length.should == count.to_i
end

When /^I create mock instance$/ do
  inst = Factory.build :mock_running_instance
  visit instances_url, :post, 'instance[name]' => inst.name, 'instance[assembly_xml]' => inst[:deployment_xml], 'instance.image_uuid' => inst.image_uuid, 'instance.image_build_uuid' => inst.image_build_uuid
end

Then /^I should see mock instance in JSON format$/ do
  data = ActiveSupport::JSON.decode(page.source)
  data['name'].should == mock_instance.name
end

Then /^I should get back instance in JSON format$/ do
  data = ActiveSupport::JSON.decode(page.source)
  data.should_not be_blank
end

When /^I stop "([^"]*)" instance$/ do |arg1|
  inst = Instance.find_by_name(arg1)
  visit multi_stop_instances_url('instance_selected[]' => inst.id)
end

Then /^I should get back JSON object with success and errors$/ do
  data = ActiveSupport::JSON.decode(page.source)
  data['success'].should_not be_nil
  data['errors'].should_not be_nil
end
