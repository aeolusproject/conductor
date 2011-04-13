Given /^the account has an instance associated with it$/ do
  Factory :instance, :provider_account => @provider_account
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
  @provider = Provider.find_by_name('testprovider')
  @provider_account = Factory(:mock_provider_account, :provider => @provider, :label => label)
end

Given /^there is a second provider account named "([^"]*)"$/ do |label|
  @provider =  Factory(:provider, :name => 'secondprovider')
  @provider_account = Factory(:provider_account, :provider => @provider, :label => label)
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
