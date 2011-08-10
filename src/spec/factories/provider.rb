FactoryGirl.define do

  factory :provider do
    sequence(:name) { |n| "provider#{n}" }
    provider_type { Factory.build :provider_type }
    url { |p| "http://www." + p.name + ".com/api" }
  end

  factory :mock_provider, :parent => :provider do
    provider_type {ProviderType.find_by_deltacloud_driver("mock")}
    url 'http://localhost:3002/api'
    hardware_profiles { |hp| [hp.association(:mock_hwp1), hp.association(:mock_hwp2)] }
    after_create { |p| p.realms << FactoryGirl.create(:realm1, :provider => p) << FactoryGirl.create(:realm2, :provider => p) }
  end

  factory :mock_provider2, :parent => :provider do
    name 'mock2'
    provider_type { ProviderType.find_by_deltacloud_driver("mock") }
    url 'http://localhost:3002/api'
    after_create { |p| p.realms << FactoryGirl.create(:realm3, :provider => p) }
  end

  factory :ec2_provider, :parent => :provider do
    name 'amazon-ec2'
    provider_type { ProviderType.find_by_deltacloud_driver("ec2") }
    url 'http://localhost:3002/api'
    hardware_profiles { |hp| [hp.association(:ec2_hwp1)] }
    after_create { |p| p.realms << FactoryGirl.create(:realm4, :provider => p) }
  end

  factory :disabled_provider, :parent => :mock_provider do
    enabled false
  end

end
