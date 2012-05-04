World(Rack::Test::Methods)

Given /^I use my authentication credentials in each request$/ do
  authorize(@user.login, 'secret')
end

When /^I request a list of providers returned as XML$/ do
  header 'Accept', 'application/xml'
  get providers_path
end

# TODO: complete tests for list of providers
Then /^I should receive list of providers as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
end
