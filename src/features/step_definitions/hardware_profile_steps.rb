Given /^there are the following conductor hardware profiles:$/ do |table|
  table.hashes.each do |hash|
    create_hwp(hash)
  end
end

Given /^the Hardare Profile "([^"]*)" has the following Provider Hardware Profiles:$/ do |name, table|
  provider = FactoryGirl.create :mock_provider
  front_end_hwp = HardwareProfile.find_by_name(name)
  back_end_hwps = table.hashes.collect { |hash| create_hwp(hash, provider) }
end

Given /^there is a "([^"]*)" hardware profile$/ do |arg1|
  FactoryGirl.create(:mock_hwp1, :name => arg1)
end

def create_hwp(hash, provider=nil)
  memory = FactoryGirl.create(:mock_hwp1_memory, :value => hash[:memory])
  storage = FactoryGirl.create(:mock_hwp1_storage, :value => hash[:storage])
  cpu = FactoryGirl.create(:mock_hwp1_cpu, :value => hash[:cpu])
  arch = FactoryGirl.create(:mock_hwp1_arch, :value => hash[:architecture])
  FactoryGirl.create(:mock_hwp1, :name => hash[:name], :memory => memory, :cpu => cpu, :storage => storage, :architecture => arch, :provider => provider)
end

When /^I enter the following details for the Hardware Profile Properties$/ do |table|
  table.hashes.each do |hash|
    hash.each_pair do |key, value|
      if !(hash[:name] == "architecture" || key == "name")
        When "I fill in \"#{"hardware_profile_" + hash[:name] + "_attributes_" + key}\" with \"#{value}\""
      elsif hash[:name] == "architecture" && key == 'value'
        When "I select \"#{value}\" from \"#{"hardware_profile_" + hash[:name] + "_attributes_" + key}\""
      end
    end
  end
end

Given /^there are the following provider hardware profiles:$/ do |table|
  provider = FactoryGirl.create :mock_provider
  create_provider_hardware_profiles(provider, table)
end

Given /^there are (\d+) hardware profiles$/ do |count|
  count.to_i.times do |i|
    FactoryGirl.create(:mock_hwp1, :name => "hwprofile#{i}")
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