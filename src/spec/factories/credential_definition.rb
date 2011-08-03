FactoryGirl.define do
  factory :credential_definition do
    sequence(:name) { |n| "field#{n}" }
    sequence(:label) { |n| "field#{n}" }
    input_type 'text'
    association :provider_type
  end
end
