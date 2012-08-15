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
When /^I request a list of provider accounts for that provider returned as XML$/ do
  header 'Accept', 'application/xml'
  get api_provider_provider_accounts_path(@provider)
end

Then /^I should receive list of provider accounts for that provider as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//provider_accounts/provider_account').size.should be_eql(3)
  # TODO: test that provider accounts listed is for that provider only
end

When /^I ask for details of that provider account as XML$/ do
  header 'Accept', 'application/xml'
  get api_provider_account_path(@provider_account)
end

Then /^I should receive details of that provider account as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//provider_account').size.should be_eql(1)
end

When /^I ask for details of non existing provider account$/ do
  header 'Accept', 'application/xml'
  provider_account = ProviderAccount.find_by_id(1)
  provider_account.delete if provider_account
  get api_provider_account_path(1)
end

When /^I create provider account with correct data$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @new_provider_account = FactoryGirl.build(:mock_provider_account, :provider => @provider)

  credentials_hash = ''

  @new_provider_account.credentials.each do |credential|
    label = credential.credential_definition.name
    value = credential.value
    credentials_hash += "<#{label}>#{value}</#{label}>"
  end

  xml_provider_account = %Q[<?xml version="1.0" encoding="UTF-8"?>
                              <provider_account>
                              <label>#{@new_provider_account.label}</label>
                              <credentials>
    #{credentials_hash}
                              </credentials>
                              </provider_account>
  ]

  post api_provider_provider_accounts_url(@provider), xml_provider_account
end

When /^I create provider account with incorrect data$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @new_provider_account = FactoryGirl.build(:mock_provider_account, :provider => @provider)

  credentials_hash = ''

  @new_provider_account.credentials.each do |credential|
    label = credential.credential_definition.name
    value = credential.value
    credentials_hash += "<#{label}>#{value}</#{label}>"
  end

  # missing label to achive incorrect data
  xml_provider_account = %Q[<?xml version="1.0" encoding="UTF-8"?>
                              <provider_account>
                              <credentials>
    #{credentials_hash}
                              </credentials>
                              </provider_account>
  ]

  post api_provider_provider_accounts_url(@provider), xml_provider_account
end


When /^I update that provider account with correct data$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @new_provider_account = FactoryGirl.build(:mock_provider_account, :provider => @provider)

  credentials_hash = ''

  @new_provider_account.credentials.each do |credential|
    label = credential.credential_definition.name
    value = credential.value
    credentials_hash += "<#{label}>#{value}</#{label}>"
  end

  xml_provider_account = %Q[<?xml version="1.0" encoding="UTF-8"?>
                                <provider_account>
                                <label>#{@new_provider_account.label}</label>
                                <credentials>
    #{credentials_hash}
                                </credentials>
                                </provider_account>
  ]

  put api_provider_account_url(@provider_account), xml_provider_account
end

When /^I update that provider account with incorrect data$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @other_provider_account = FactoryGirl.build(:mock_provider_account_seq, :provider => @provider)
  @other_provider_account.stub(:validate_credentials).and_return(true)
  @other_provider_account.save
  @new_provider_account = FactoryGirl.build(:mock_provider_account_seq, :provider => @provider)

  credentials_hash = ''

  @new_provider_account.credentials.each do |credential|
    label = credential.credential_definition.name
    value = credential.value
    credentials_hash += "<#{label}>#{value}</#{label}>"
  end

  xml_provider_account = %Q[<?xml version="1.0" encoding="UTF-8"?>
                                <provider_account>
                                <label>#{@other_provider_account.label}</label>
                                <credentials>
    #{credentials_hash}
                                </credentials>
                                </provider_account>
  ]

  put api_provider_account_url(@provider_account), xml_provider_account
end

When /^I attempt to update the provider account$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @new_provider_account = FactoryGirl.build(:mock_provider_account, :provider => @provider)

  credentials_hash = ''

  @new_provider_account.credentials.each do |credential|
    label = credential.credential_definition.name
    value = credential.value
    credentials_hash += "<#{label}>#{value}</#{label}>"
  end

  xml_provider_account = %Q[<?xml version="1.0" encoding="UTF-8"?>
                                <provider_account>
                                <label>#{@new_provider_account.label}</label>
                                <credentials>
    #{credentials_hash}
                                </credentials>
                                </provider_account>
  ]

  put api_provider_account_url(@provider_account), xml_provider_account
end

Then /^the provider account should be updated$/ do
  orig_attrs, current_attrs, updating_attrs  = [ @provider_account.dup, @provider_account.reload, @new_provider_account ].map do |pro|
    pro.attributes.except("quota_id", "id", "lock_version", "updated_at", "created_at")
  end
  current_attrs.should be_eql(updating_attrs)
  current_attrs.should_not be_eql(orig_attrs)
end

Then /^the provider account should not be updated$/ do
  orig_attrs, current_attrs, updating_attrs  = [ @provider_account.dup, @provider_account.reload, @new_provider_account ].map do |pro|
    pro.attributes.except("quota_id", "id", "lock_version", "updated_at", "created_at")
  end
  current_attrs.should_not be_eql(updating_attrs)
  current_attrs.should be_eql(orig_attrs)
end

Given /^the specified provider account does not exist in the system$/ do
  @provider_account = FactoryGirl.create(:mock_provider_account)
  ProviderAccount.delete(@provider_account.id)
end
