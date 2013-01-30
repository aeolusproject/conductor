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
Given /^there is an image "([^"]*)"$/ do |name|
  @image = FactoryGirl.create(:base_image_with_template, :name => name)
end

When /^I fill in "([^"]*)" with an invalid XML$/ do |arg1|
  xml = '<?xml version="1.0"?><template>'
  fill_in(arg1, :with => xml)
end

Given /^an image build request will succeed$/ do
  Tim::TargetImage.any_instance.stub(:create_factory_target_image).and_return(true)
end
