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
  @provider = Provider.find_by_name('testprovider')
  @provider_account = FactoryGirl.create(:mock_provider_account, :provider => @provider, :label => label)
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
  provider =  FactoryGirl.create(:ec2_provider, :name => 'ec2provider')
  FactoryGirl.create(:ec2_provider_account, :label => arg1, :provider => provider)
end

Given /^there is mock provider account "([^"]*)"$/ do |arg1|
  provider =  FactoryGirl.create(:mock_provider, :name => 'mockprovider')
  FactoryGirl.create(:mock_provider_account, :label => arg1, :provider => provider)
end

Then /^there should be these mock provider accounts:$/ do |table|
  accounts = @xml_response.root.xpath('/provider_accounts/provider_account').map do |n|
    {:name => n.xpath('name').text,
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
    {:name => n.xpath('name').text,
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
