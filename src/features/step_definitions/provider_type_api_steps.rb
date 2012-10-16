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

When /^I request a list of provider types returned as XML$/ do
  header 'Accept', 'application/xml'
  get api_provider_types_path
end

Then /^I should receive list of provider types as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//provider_types/provider_type').size.should be_eql(3)
end

When /^I ask for details of that provider type as XML$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'
  get api_provider_type_path(@provider_type.id)
end

Then /^I should receive details of that provider type as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//provider_type').size.should be_eql(1)
end

When /^I ask for details of non existing provider type$/ do
  header 'Accept', 'application/xml'
  provider_type = ProviderType.find_by_id(1)
  provider_type.delete if provider_type
  get api_provider_type_path(1)
end
