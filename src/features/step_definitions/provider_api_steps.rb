World(Rack::Test::Methods)

Given /^I use my authentication credentials in each request$/ do
  authorize(@user.login, 'secret')
end

When /^I request a list of providers returned as XML$/ do
  header 'Accept', 'application/xml'
  get api_providers_path
end

Then /^I should receive list of providers as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//providers/provider').size.should be_eql(3)
end

When /^I ask for details of that provider as XML$/ do
  header 'Accept', 'application/xml'
  get api_provider_path(@provider.id)
end

Then /^I should recieve details of that provider as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//provider').size.should be_eql(1)
end

When /^I ask for details of non existing provider as XML$/ do
  header 'Accept', 'application/xml'
  provider = Provider.find_by_id(1)
  provider.delete if provider
  get api_provider_path(1)
end

Then /^I should recieve Not Found error$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(404)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//error').size.should be_eql(1)
end
