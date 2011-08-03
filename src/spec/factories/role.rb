FactoryGirl.define do
  factory :role do
    sequence(:name) { |n| "Role name #{n}" }
    scope 'Pool'
  end
end
