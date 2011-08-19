FactoryGirl.define do
  factory :catalog do
    sequence(:name) { |n| "catalog#{n}" }
    association :pool, :factory => :pool
  end
end
