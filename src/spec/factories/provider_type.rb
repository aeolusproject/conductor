FactoryGirl.define do

  factory :provider_type do
    sequence(:name) { |n| "name#{n}" }
    sequence(:deltacloud_driver) { |n| "deltacloud_driver#{n}" }
  end

  factory :mock_provider_type, :parent => :provider_type do
    name 'Mock'
    deltacloud_driver 'mock'
  end

  factory :ec2_provider_type, :parent => :provider_type do
    name 'Amazon EC2'
    deltacloud_driver 'ec2'
  end

end
