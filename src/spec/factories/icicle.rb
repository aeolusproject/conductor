FactoryGirl.define do
  factory :icicle do
    sequence(:uuid) { |n| "icicle#{n}" }
  end
end
