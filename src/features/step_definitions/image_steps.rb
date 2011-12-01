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
Given /^there is an image$/ do
  @image = Aeolus::Image::Warehouse::Image.first
end

When /^I click on the image$/ do
  click_link(@image.name)
end

Then /^I should see the image's name$/ do
  if page.respond_to? :should
    page.should have_content(@image.name)
  else
    assert page.has_content?(@image.name)
  end
end
