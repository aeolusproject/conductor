Then /^there should be these provider types:$/ do |table|
  types = @xml_response.root.xpath('/provider_types/provider_type').map do |n|
    {:name            => n.xpath('name').text,
     :codename        => n.xpath('codename').text,
     :build_supported => n.xpath('build_supported').text}
  end
  table.hashes.each do |hash|
    p = types.find {|n| n[:name] == hash[:name]}
    p.should_not be_nil
    p[:codename].should == hash[:codename]
    p[:build_supported].should == hash[:build_supported]
  end
end
