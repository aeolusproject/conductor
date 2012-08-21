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
Then /^I should see an input "([^\"]*)"$/ do |value|
  response.should have_selector("form input[value=#{value}]")
end

Then /^I should see a confirmation message$/ do
  page.should have_selector '.flash-group.notice .flash-subset'
end

Then /^I should see a warning message$/ do
  page.should have_selector '.flash-group.warning .flash-subset'
end

Then /^I should see an error message$/ do
  page.should have_selector '.flash-group.error .flash-subset'
end

module LocalizationHelpers
  def localized_text_present(selector)
    text = I18n.translate!(selector)
    text_present(text)
  end

  def text_present(text)
    if page.respond_to? :should
      page.should have_content(text)
    else
      assert page.has_content?(text)
    end
  end
end
World(LocalizationHelpers)

def mock_deltacloud
  @deltacloud_connection = mock("Deltacloud::API")

  @running_state = mock("Deltacloud::API::InstanceState")
  @running_state.stub(:transitions).and_return {
    [create_deltacloud_transition('running', 'reboot'),
     create_deltacloud_transition('stopped', 'stop')]}
  @deltacloud_connection.stub(:instance_state).with("running").and_return(@running_state)

  @stopped_state = mock("Deltacloud::API::InstanceState")
  @stopped_state.stub(:transitions).and_return {
    [create_deltacloud_transition('running', 'start'),
     create_deltacloud_transition('finish', 'destroy')]}
  @deltacloud_connection.stub(:instance_state).with("stopped").and_return(@stopped_state)

  ProviderAccount.any_instance.stub(:connect).and_return(@deltacloud_connection)
end

private

def create_deltacloud_transition(to_state, action_to_get_to_state)
  deltacloud_transition = mock("Deltacloud::API::Transition")
  deltacloud_transition.stub(:to).and_return(to_state)
  deltacloud_transition.stub(:action).and_return(action_to_get_to_state)
  deltacloud_transition
end
