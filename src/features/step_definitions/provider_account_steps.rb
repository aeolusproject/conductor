Then /^there should be no provider accounts$/ do
  CloudAccount.all.should be_empty
end

Given /^there are no provider accounts$/ do
  CloudAccount.all.should be_empty
end

When /^I attach the "([^"\s]+)" file to "([^"\s]+)"$/ do |file, field|
  path = File.join(RAILS_ROOT, 'features', 'upload_files', file)
  attach_file(field, path, 'text/plain')
end

Then /^I should have a provider account named "([^"]*)"$/ do |label|
  CloudAccount.find_by_label(label).should_not be_nil
end

Given /^there is a provider account named "([^"]*)"$/ do |label|
  @provider = Provider.find_by_name('testprovider')
  @cloud_account = Factory(:mock_cloud_account, :provider => @provider, :label => label)
end

Given /^there is a second provider account named "([^"]*)"$/ do |label|
  @provider =  Factory(:mock_provider, :name => 'secondprovider')
  @cloud_account = Factory(:mock_cloud_account, :provider => @provider, :label => label)
end


When /^I check the "([^"]*)" account$/ do |label|
  account = CloudAccount.find_by_label(label)
  check("account_checkbox_#{account.id}")
end

Given /^that there are these provider accounts:$/ do |table|
  table.hashes.each do |hash|
     Factory.create(:cloud_account, :name => hash['name'], :username => hash['username'])
  end
end
