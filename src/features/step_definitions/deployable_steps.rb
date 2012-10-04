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
When /^I check "([^"]*)" catalog entry$/ do |arg1|
  dep = Deployable.find_by_name(arg1)
  check("deployable_checkbox_#{dep.id}")
end

Then /^there should be only (\d+) catalog entries for "([^"]*)" catalog$/ do |arg1, catalog_name|
  catalog = Catalog.find_by_name(catalog_name) || FactoryGirl.create(:catalog, :name => catalog_name)
  catalog.catalog_entries.count.should == arg1.to_i
end

Given /^a catalog entry "([^"]*)" exists for "([^"]*)" catalog$/ do |arg1, catalog_name|
  catalog = Catalog.find_by_name(catalog_name) || FactoryGirl.create(:catalog, :name => catalog_name)
  deployable = FactoryGirl.create :deployable, :name => arg1, :catalogs => [catalog]
end

Given /^images for "([^"]*)" catalog entry are pushed$/ do |catalog_entry_name|
  deployable = Deployable.find_by_name(catalog_entry_name)
  image_uuids = deployable.get_image_details[0].map { |assembly| assembly[:image_uuid] }
  ProviderAccount.any_instance.
    stub(:image_status).
    with { |image| image_uuids.include? image.uuid }.
    and_return(:pushed)
end
