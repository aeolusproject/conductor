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
Given /^there is a "([^"]*)" catalog$/ do |name|
  FactoryGirl.create :catalog, :name => name
end

When /^I check "([^"]*)" catalog$/ do |arg1|
  catalog = Catalog.find_by_name(arg1)
  check("catalog_checkbox_#{catalog.id}")
end
