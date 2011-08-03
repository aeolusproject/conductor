FactoryGirl.define do
  factory :frontend_realm do
    sequence(:name) { |n| "realm#{n}" }
  end
end
