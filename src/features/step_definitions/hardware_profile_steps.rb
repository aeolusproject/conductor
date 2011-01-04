Given /^there are the following aggregator hardware profiles:$/ do |table|
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

def create_hwp(hash, provider=nil)
  memory = Factory(:mock_hwp1_memory, :value => hash[:memory])
  storage = Factory(:mock_hwp1_storage, :value => hash[:storage])
  cpu = Factory(:mock_hwp1_cpu, :value => hash[:cpu])
  arch = Factory(:mock_hwp1_arch, :value => hash[:architecture])
  Factory(:mock_hwp1, :name => hash[:name], :memory => memory, :cpu => cpu, :storage => storage, :architecture => arch, :provider => provider)
end