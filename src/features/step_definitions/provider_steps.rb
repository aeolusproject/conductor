Given /^there should not exist a provider named "([^\"]*)"$/ do |name|
  Provider.find_by_name(name).should be_nil
end

Given /^there is not a provider named "([^"]*)"$/ do |name|
  provider = Provider.find_by_name(name)
  if provider then provider.destroy end
end

Given /^there is a provider named "([^\"]*)"$/ do |name|
  @provider = Factory(:mock_provider, :name => name)
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

Given /^there are these providers:$/ do |table|
  table.hashes.each do |hash|
    hash['url'].nil? ? Factory(:mock_provider, :name => hash['name']) : Factory(:mock_provider, :name => hash['name'], :url => hash['url'])
  end
end

Given /^this provider has (\d+) replicated images$/ do |number|
  number.to_i.times { |i| Factory(:replicated_image, :provider => @provider) }
end

Given /^this provider has (\d+) hardware profiles$/ do |number|
  number.to_i.times { |i| Factory(:mock_hwp1, :provider => @provider) }
end


Given /^this provider has a realm$/ do
  Factory(:realm, :provider => @provider)
end

Given /^this provider has a cloud account$/ do
  Factory(:mock_cloud_account, :provider => @provider)
end

Then /^there should not be any replicated images$/ do
  ReplicatedImage.find(:all, :conditions => { :provider_id => @provider.id} ).size.should == 0
end

Then /^there should not be any hardware profiles$/ do
  HardwareProfile.find(:all, :conditions => { :provider_id => @provider.id} ).size.should == 0
end

Then /^there should not be a cloud account$/ do
  CloudAccount.find(:all, :conditions => { :provider_id => @provider.id} ).size.should == 0
end

Then /^there should not be a realm$/ do
  Realm.find(:all, :conditions => { :provider_id => @provider.id} ).size.should == 0
end
