Then /^I should see an input "([^\"]*)"$/ do |value|
  response.should have_selector("form input[value=#{value}]")
end
