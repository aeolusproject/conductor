Then /^there should be these provider types:$/ do |table|
  types = @xml_response.root.xpath('/provider_types/provider_type').map do |n|
    {:name              => n.xpath('name').text,
     :deltacloud_driver => n.xpath('deltacloud_driver').text}
  end
  table.hashes.each do |hash|
    p = types.find {|n| n[:name] == hash[:name]}
    p.should_not be_nil
    p[:deltacloud_driver].should == hash[:deltacloud_driver]
  end
end
