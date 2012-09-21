#
#   Copyright 2012 Red Hat, Inc.
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

When /^I request a list of catalogs returned as XML$/ do
  header 'Accept', 'application/xml'
  get api_catalogs_path
end

When /^I ask for details of that catalog as XML$/ do
  header 'Accept', 'application/xml'
  get api_catalog_path(@catalog.id)
end

Then /^I should receive list of catalogs as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should == 200
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//catalogs/catalog').size.should == @catalogs.size
end

Then /^I should receive details of that catalog as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should == 200
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//catalog').size.should == 1
  xml_body.xpath('//catalog/name').text.should == @catalog.name
end
