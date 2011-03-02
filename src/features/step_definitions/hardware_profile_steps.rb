Given /^there are the following conductor hardware profiles:$/ do |table|
  table.hashes.each do |hash|
    create_hwp(hash)
  end
end

Given /^the Hardare Profile "([^"]*)" has the following Provider Hardware Profiles:$/ do |name, table|
  provider = Factory :mock_provider
  front_end_hwp = HardwareProfile.find_by_name(name)
  back_end_hwps = table.hashes.collect { |hash| create_hwp(hash, provider) }

  front_end_hwp.provider_hardware_profiles = back_end_hwps
  front_end_hwp.save!
end

Given /^there is a "([^"]*)" hardware profile$/ do |arg1|
  Factory(:mock_hwp1, :name => arg1)
end

def create_hwp(hash, provider=nil)
  memory = Factory(:mock_hwp1_memory, :value => hash[:memory])
  storage = Factory(:mock_hwp1_storage, :value => hash[:storage])
  cpu = Factory(:mock_hwp1_cpu, :value => hash[:cpu])
  arch = Factory(:mock_hwp1_arch, :value => hash[:architecture])
  Factory(:mock_hwp1, :name => hash[:name], :memory => memory, :cpu => cpu, :storage => storage, :architecture => arch, :provider => provider)
end

When /^I enter the following details for the Hardware Profile Properties$/ do |table|
  table.hashes.each do |hash|
    hash.each_pair do |key, value|
      unless (hash[:name] == "architecture" && (key == "range_first" || key == "range_last" || key == "property_enum_entries")) || key == "name"
        When "I fill in \"#{"hardware_profile_" + hash[:name] + "_attributes_" + key}\" with \"#{value}\""
      end
    end
  end
end

Given /^there are the following provider hardware profiles:$/ do |table|
  provider = Factory :mock_provider
  create_provider_hardware_profiles(provider, table)
end

Given /^there are (\d+) hardware profiles$/ do |count|
  count.to_i.times do |i|
    Factory(:mock_hwp1, :name => "hwprofile#{i}")
  end
end

Given /^"([^"]*)" has the following hardware profiles:$/ do |provider_name, table|
  provider = Provider.find_by_name(provider_name)
  create_provider_hardware_profiles(provider, table)
end

def create_provider_hardware_profiles(provider, table)
  table.hashes.each do |hash|
    create_hwp(hash, provider)
  end
end