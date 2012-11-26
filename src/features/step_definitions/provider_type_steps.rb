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

Given /^there are some provider types$/ do
  ProviderType.destroy_all
  3.times do
    FactoryGirl.create(:provider_type)
  end
  @provider_type_count = ProviderType.count
  @provider_type_count.should be_eql(3)
end

Given /^there is a provider type$/ do
  ProviderType.destroy_all
  @provider_type = FactoryGirl.create(:provider_type)
end

Then /^the provider type should be deleted$/ do
  ProviderType.where(:name => @provider_type.name, :deltacloud_driver => @provider_type.deltacloud_driver).should be_empty
end

Then /^no provider type should be deleted$/ do
  ProviderType.count.should be_eql(@provider_type_count)
end

Given /^the specified provider type does not exist in the system$/ do
  @provider_type = FactoryGirl.create(:provider_type)
  ProviderType.destroy(@provider_type.id)
  ProviderType.where(:id => @provider_type.id).should be_empty
end
