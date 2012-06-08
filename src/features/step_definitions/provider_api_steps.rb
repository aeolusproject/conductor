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

Then /^I should receive details of that provider as XML$/ do
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

Then /^I should receive Not Found error$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(404)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//error').size.should be_eql(1)
end

When /^I create provider with correct data via XML$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @provider = FactoryGirl.build(:mock_provider)

  xml_provider = %Q[<?xml version="1.0" encoding="UTF-8"?>
                    <provider>
                    <name>#{@provider.name}</name>
                    <url>#{@provider.url}</url>
                    <provider_type id="#{@provider.provider_type_id}" />
                    </provider>
                    ]

  post api_providers_path, xml_provider
end

Then /^I should received?(?: an)? OK message$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
end

When /^I create provider with incorrect data via XML$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @provider = FactoryGirl.build(:invalid_provider)

  xml_provider = %Q[<?xml version="1.0" encoding="UTF-8"?>
                    <provider>
                    <name>#{@provider.name}</name>
                    <url>#{@provider.url}</url>
                    <provider_type_id>#{@provider.provider_type_id}</provider_type_id>
                    </provider>
                    ]

  post api_providers_path, xml_provider
end

Then /^I should receive Bad Request message$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(400)
end

When /^I delete that provider via XML$/ do
  header 'Accept', 'application/xml'

  delete api_provider_path(@provider)
end

When /^I attempt to delete the provider$/ do
  header 'Accept', 'application/xml'

  delete api_provider_path(@provider)
end

Then /^I should receive a Provider Not Found error$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(404)
end

When /^I update that provider with correct data via XML$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @provider = FactoryGirl.create(:mock_provider)
  @new_provider = FactoryGirl.build(:mock_provider)

  xml_provider = %Q[<?xml version="1.0" encoding="UTF-8"?>
                    <provider>
                    <name>#{@new_provider.name}</name>
                    <url>#{@new_provider.url}</url>
                    <provider_type id="#{@new_provider.provider_type_id}" />
                    </provider>
                    ]

  put api_provider_path(@provider), xml_provider
end

Then /^the provider should be updated$/ do
  orig_attrs, current_attrs, updating_attrs  = [ @provider.dup, @provider.reload, @new_provider ].map do |pro|
    pro.attributes.except("id", "lock_version", "updated_at", "created_at")
  end
  current_attrs.should be_eql(updating_attrs)
  current_attrs.should_not be_eql(orig_attrs)
end

When /^I update that provider with incorrect data via XML$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @provider = FactoryGirl.create(:mock_provider)
  other_provider = FactoryGirl.create(:mock_provider)
  @new_provider = FactoryGirl.build(:invalid_provider, :name => other_provider.name)

  xml_provider = %Q[<?xml version="1.0" encoding="UTF-8"?>
                    <provider>
                    <name>#{@new_provider.name}</name>
                    <provider_type id="#{@new_provider.provider_type_id}" />
                    </provider>
                    ]

  put api_provider_path(@provider), xml_provider
end

Then /^the provider should not be updated$/ do
  orig_attrs, current_attrs, updating_attrs  = [ @provider.dup, @provider.reload, @new_provider ].map do |pro|
    pro.attributes.except("id", "lock_version", "updated_at", "created_at")
  end
  current_attrs.should_not be_eql(updating_attrs)
  current_attrs.should be_eql(orig_attrs)
end
