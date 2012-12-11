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
Given /^the account has an instance associated with it$/ do
  FactoryGirl.create :instance, :provider_account => @provider_account
end

Given /^all the account instances are stopped$/ do
  @provider_account.instances.each do |i|
    i.state = Instance::STATE_STOPPED
    i.save
  end
end

When /^I delete all instances from the account$/ do
  @provider_account.instances.each do |i|
    i.state = Instance::STATE_STOPPED
    i.destroy
  end
end

Then /^there should be no provider accounts$/ do
  ProviderAccount.all.should be_empty
end

Then /^there should be (\d+) provider accounts?$/ do |count|
  ProviderAccount.all.length.should == count.to_i
end

Given /^there are no provider accounts$/ do
  ProviderAccount.all.should be_empty
end

When /^I attach the "([^"\s]+)" file to "([^"\s]+)"$/ do |file, field|
  path = File.join(RAILS_ROOT, 'features', 'upload_files', file)
  attach_file(field, path, 'text/plain')
end

Then /^I should have a provider account named "([^"]*)"$/ do |label|
  ProviderAccount.find_by_label(label).should_not be_nil
end

Given /^there is a provider account named "([^"]*)"$/ do |label|
  @provider = Provider.find_by_name('mockprovider')
  @provider_account = FactoryGirl.create(:mock_provider_account, :provider => @provider, :label => label)
end

Given /^there is a provider account$/ do
  @provider_account = FactoryGirl.create(:mock_provider_account, :provider => @provider)
end

Given /^there is a second provider account named "([^"]*)"$/ do |label|
  @provider =  FactoryGirl.create(:provider, :name => 'secondprovider')
  @provider_account = FactoryGirl.create(:provider_account, :provider => @provider, :label => label)
end


When /^I check the "([^"]*)" account$/ do |label|
  account = ProviderAccount.find_by_label(label)
  check("account_checkbox_#{account.id}")
end

Given /^that there are these provider accounts:$/ do |table|
  table.hashes.each do |hash|
     Factory.create(:provider_account, :name => hash['name'], :username => hash['username'])
  end
end

Given /^there is ec2 provider account "([^"]*)"$/ do |arg1|
  provider =  FactoryGirl.create(:ec2_provider, :name => 'ec2-provider')
  FactoryGirl.create(:ec2_provider_account, :label => arg1, :provider => provider)
end

Given /^there is mock provider account "([^"]*)"$/ do |arg1|
  if (provider = Provider.find_by_name('mock'))
    if account = provider.provider_accounts.first
      account.label = arg1
      account.save
    else
      FactoryGirl.create(:mock_provider_account, :label => arg1, :provider => provider)
    end
  else
    provider = FactoryGirl.create(:mock_provider, :name => 'mock')
    FactoryGirl.create(:mock_provider_account, :label => arg1, :provider => provider)
  end
end

Then /^there should be these mock provider accounts:$/ do |table|
  accounts = @xml_response.root.xpath('/provider_accounts/provider_account').map do |n|
    {:name => n.xpath('label').text,
     :provider  => n.xpath('provider').text,
     :username => n.xpath('username').text,
     :password => n.xpath('password').text,
     :provider_type  => n.xpath('provider_type').text}
  end
  table.hashes.each do |hash|
    p = accounts.find {|n| n[:name] == hash[:name]}
    p.should_not be_nil
    p[:provider].should == hash[:provider]
    p[:username].should == hash[:username]
    p[:password].should == hash[:password]
    p[:provider_type].should == hash[:provider_type]
  end
end

Then /^there should be these ec2 provider accounts:$/ do |table|
  accounts = @xml_response.root.xpath('/provider_accounts/provider_account').map do |n|
    {:name => n.xpath('label').text,
     :provider  => n.xpath('provider').text,
     :access_key => n.xpath('access_key').text,
     :secret_access_key => n.xpath('secret_access_key').text,
     :provider_type  => n.xpath('provider_type').text}
  end
  table.hashes.each do |hash|
    p = accounts.find {|n| n[:name] == hash[:name]}
    p.should_not be_nil
    p[:provider].should == hash[:provider]
    p[:access_key].should == hash[:access_key]
    p[:secret_access_key].should == hash[:secret_access_key]
    p[:provider_type].should == hash[:provider_type]
  end
end

Given /^there are some provider accounts for given provider$/ do
  # FIXME: change 3 to constant
  3.times do
    pa = FactoryGirl.build(:mock_provider_account_seq, :provider => @provider)
    pa.stub!(:validate_credentials).and_return(true)
    pa.save
  end
  @provider.provider_accounts.size.should be_eql(3)
end

Given /^there are some provider accounts for that another provider$/ do
  # FIXME: change 3 to constant
  3.times do
    pa = FactoryGirl.build(:mock_provider_account_seq, :provider => @another_provider)
    pa.stub!(:validate_credentials).and_return(true)
    pa.save
  end
  @another_provider.provider_accounts.size.should be_eql(3)
end


Then /^the provider account should be created$/ do
  ProviderAccount.find_by_label(@new_provider_account.label).should_not be_nil
end

Then /^the provider account should not be created$/ do
  ProviderAccount.find_by_label(@new_provider_account.label).should be_nil
end
