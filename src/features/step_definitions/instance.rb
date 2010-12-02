def mock_instance
  @mock_instance ||= Factory :mock_running_instance
end

def pending_instance
  @pending_instance ||= Factory :mock_pending_instance
end

Given /^a mock running instance exists$/ do
  mock_instance
end

Given /^a mock pending instance exists$/ do
  pending_instance
end

Given /^I am viewing the mock instance detail$/ do
  visit url_for :action => 'show', :controller => 'instance',
    :id => mock_instance
end

When /^I am viewing the pending instance detail$/ do
  visit url_for :action => 'show', :controller => 'instance',
    :id => pending_instance
end

When /^I manually go to the key action for this instance$/ do
   visit url_for :action => 'key', :controller => 'instance',
    :id => pending_instance
end

Given /^I see "([^"]*)"$/ do |text|
  response.should contain(text)
end

Then /^I should see the Save dialog for a (.+) file$/ do |filetype|
  response.headers["Content-Disposition"].should
  match(/^attachment;\sfilename=.*#{filetype}$/)
end