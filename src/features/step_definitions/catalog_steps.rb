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
Given /^there is a catalog$/ do
  @catalog = FactoryGirl.create :catalog
end

Given /^there is a "([^"]*)" catalog$/ do |name|
  FactoryGirl.create :catalog, :name => name
end

Given /^there is a "([^"]*)" catalog with deployable$/ do |name|
  FactoryGirl.create :catalog_with_deployable, :name => name
end

Given /^there are some catalogs$/ do
  @catalogs = Catalog.all
  3.times { @catalogs << FactoryGirl.create(:catalog) }
end

Given /^the specified catalog does not exist in the system$/ do
  @catalog = FactoryGirl.build :catalog, :id => 123456, :name => 'non-existent catalog'
end

When /^I check "([^"]*)" catalog$/ do |arg1|
  catalog = Catalog.find_by_name(arg1)
  check("catalog_checkbox_#{catalog.id}")
end

Then /^the catalog should be created$/ do
  Catalog.find_by_name(@catalog.name).should_not be_nil
end

Then /^the catalog should not be created$/ do
  Catalog.find_by_name(@catalog.name).should be_nil
end
