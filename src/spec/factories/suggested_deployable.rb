FactoryGirl.define do
  factory :suggested_deployable do
    sequence(:name) { |n| "suggested_deployable#{n}" }
    url "http://url_to_deployable"
    description "suggested deployable description"
    association :owner, :factory => :user
  end
end
