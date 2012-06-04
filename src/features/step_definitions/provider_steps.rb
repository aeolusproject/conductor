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
def new_provider(port,bool)
  destroy_provider("testprovider")
  stub_framework(bool)
  fill_in "provider[name]", :with => "testprovider"
  fill_in "provider[url]", :with => "http://localhost:#{port}/api"
  select("Amazon EC2", :from => "provider_provider_type_id")
  click_button "save"
end

def destroy_provider(name)
  provider = Provider.find_by_name(name)
  if provider then provider.destroy end
end

def stub_framework(bool)
  Provider.any_instance.stub(:valid_framework?).and_return(bool)
end

Then /^the provider should be created$/ do
  Provider.find_by_name_and_url(@provider.name, @provider.url).should_not be_nil
end

Then /^the provider should not be created$/ do
  Provider.find_by_name_and_url(@provider.name, @provider.url).should be_nil
end

Then /^the provider should be deleted$/ do
  Provider.find_by_name_and_url(@provider.name, @provider.url).should be_nil
end

Then /^no provider should be deleted$/ do
  # FIXME better way to test this?
  Provider.count.should be_eql(@provider_count)
end

Then /^the provider should not be deleted$/ do
  Provider.find_by_name_and_url(@provider.name, @provider.url).should_not be_nil
end

Given /^there should not exist a provider named "([^\"]*)"$/ do |name|
  Provider.find_by_name(name).should be_nil
end

Given /^the specified provider does not exist in the system$/ do
  @provider = FactoryGirl.create(:mock_provider)
  Provider.delete(@provider.id)
  @provider_count = Provider.count
end

Given /^there is not a provider named "([^"]*)"$/ do |name|
  destroy_provider(name)
end

Given /^there is not (?:a )?provider with id "([^"]*)"$/ do |id|
  provider = Provider.find_by_id(id.to_i)
  if provider then provider.destroy end
end

Given /^there is a provider named "([^\"]*)"$/ do |name|
  @provider = FactoryGirl.create(:mock_provider, :name => name)
end

Given /^there is a provider$/ do
  @provider = FactoryGirl.create(:mock_provider)
end

Given /^provider "([^"]*)" is not accessible$/ do |arg1|
  stub_framework(false)
end

Given /^I attempt to add a valid provider$/ do
  new_provider(3002,true)
end

Given /^I attempt to add a provider with an invalid url$/ do
  new_provider(3010,false)
end

Then /^I should have a provider named "([^\"]*)"$/ do |name|
  Provider.find_by_name(name).should_not be_nil
end

When /^I follow provider settings link$/ do
  within '#provider-tabs' do |scope|
    scope.click_link "Settings"
  end
end

When /^I delete provider$/ do
  click_button "Delete provider"
end

When /^(?:|I )check "([^"]*)" provider$/ do |provider_name|
  provider = Provider.find_by_name(provider_name)
  check("provider_checkbox_#{provider.id}")
end

Given /^there are some providers$/ do
  3.times do
    FactoryGirl.create :provider
  end
end

Given /^there are these providers:$/ do |table|
  table.hashes.each do |hash|
    hash['url'].nil? ? FactoryGirl.create(:mock_provider, :name => hash['name']) : FactoryGirl.create(:mock_provider, :name => hash['name'], :url => hash['url'])
  end
end

Given /^this provider has (\d+) hardware profiles$/ do |number|
  number.to_i.times { |i| FactoryGirl.create(:mock_hwp_fake, :provider => @provider) }
end


Given /^this provider has a realm$/ do
  FactoryGirl.create(:realm, :provider => @provider)
end

Given /^this provider has a provider account$/ do
  FactoryGirl.create(:mock_provider_account, :provider => @provider)
end

Then /^there should not be any hardware profiles$/ do
  HardwareProfile.find(:all, :conditions => { :provider_id => @provider.id} ).size.should == 0
end

Then /^there should not be a provider account$/ do
  ProviderAccount.find(:all, :conditions => { :provider_id => @provider.id} ).size.should == 0
end

Then /^there should not be a realm$/ do
  Realm.find(:all, :conditions => { :provider_id => @provider.id} ).size.should == 0
end

Given /^I accept XML$/ do
  page.driver.header 'Accept', 'application/xml'
  page.driver.header 'Content-Type', 'application/xml'
end

Then /^I should get a XML document$/ do
  @xml_response = Nokogiri::XML(page.source)
end

Then /^XML should contain (\d+) providers$/ do |arg1|
  @xml_response.root.xpath('/providers/provider').count.should == arg1.to_i
end

Then /^each provider should have "([^"]*)"$/ do |arg1|
  @xml_response.root.xpath("/providers/provider/#{arg1}").text.should_not be_blank
end

Then /^there should be these provider:$/ do |table|
  providers = @xml_response.root.xpath('/providers/provider').map do |n|
    {:name => n.xpath('name').text,
     :url  => n.xpath('url').text,
     :provider_type  => n.xpath('provider_type').text}
  end
  table.hashes.each do |hash|
    p = providers.find {|n| n[:name] == hash[:name]}
    p.should_not be_nil
    p[:url].should == hash[:url]
    p[:provider_type].should == hash[:provider_type]
  end
end

Given /^this provider has a provider account with (\d+) running instances$/ do |arg1|
  pa = FactoryGirl.create(:mock_provider_account, :provider => @provider)
  arg1.to_i.times do |i|
    FactoryGirl.create(:instance, :provider_account => pa, :state => 'running')
  end
end

When /^I click on the Providers icon in the menu$/ do
  find('#administer_nav a.providers').click
end

Then /^provider "([^"]*)" should have all instances stopped$/ do |arg1|
  p = Provider.find_by_name(arg1)
  p.instances_to_terminate.should be_empty
end
