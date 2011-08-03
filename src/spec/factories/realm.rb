FactoryGirl.define do

  factory :realm do
    sequence(:name) { |n| "realm#{n}" }
    sequence(:external_key) { |n| "key#{n}" }
    association(:provider)
  end

  factory :realm1, :parent => :realm do
  end

  factory :realm2, :parent => :realm do
  end

  factory :realm3, :parent => :realm do
  end

  factory :realm4, :parent => :realm do
  end

  factory :backend_realm, :parent => :realm do
    name 'backend_name'
    external_key 'backend_key'
  end

end
