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

Given /^this provider has (\d+) provider images$/ do |number|
  number.to_i.times { |i| Factory(:legacy_provider_image, :provider => @provider) }
end

Given /^this provider has (\d+) hardware profiles$/ do |number|
  number.to_i.times { |i| Factory(:mock_hwp1, :provider => @provider) }
end


Given /^this provider has a realm$/ do
  Factory(:realm, :provider => @provider)
end

Given /^this provider has a provider account$/ do
  Factory(:mock_provider_account, :provider => @provider)
end

Then /^there should not be any provider images$/ do
  LegacyProviderImage.find(:all, :conditions => { :provider_id => @provider.id} ).size.should == 0
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
  header 'Accept', 'application/xml'
end

Then /^I should get a XML document$/ do
  @xml_response = Nokogiri::XML(response.body)
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
