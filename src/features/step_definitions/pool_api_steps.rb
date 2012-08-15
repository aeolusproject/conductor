When /^I request a list of pools as XML$/ do
  header 'Accept', 'application/xml'
  get api_pools_path
end

Then /^I should receive list of (\d+) pools as XML$/ do |number|
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
  xml_body = Nokogiri::XML(response.body)
  pool_node_set = xml_body.xpath('//pools/pool')
  pool_node_set.size.should be_eql(number.to_i)
  ids = []
  names = []
  pool_node_set.each() do |ns|
    ids << ns.get_attribute('id')
    names << ns.get_attribute('name')
  end
  ids.uniq!
  names.sort!
  # verify unique id's
  ids.size.should be_eql(number.to_i)
  if number == 3
    # verify pool names match those given in the scenario
    names.should be_eql(["Default", "bar", "foo"])
  end
end
