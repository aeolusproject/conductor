FactoryGirl.define do

  factory :provider_type do
    sequence(:name) { |n| "name#{n}" }
    sequence(:codename) { |n| "codename#{n}" }
  end

  factory :mock_provider_type, :parent => :provider_type do
    name 'Mock'
    codename 'mock'
  end

  factory :ec2_provider_type, :parent => :provider_type do
    name 'Amazon EC2'
    codename 'ec2'
  end

end
