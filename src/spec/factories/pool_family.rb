FactoryGirl.define do
  factory :pool_family do
    sequence(:name) { |n| "pool_family#{n}" }
    description 'pool family'
    association :quota
  end
end
