FactoryGirl.define do
  factory :catalog_entry do
    sequence(:name) { |n| "catalog_entry#{n}" }
    url "http://url_to_deployable"
    description "catalog entry description"
    association :owner, :factory => :user
    association :catalog, :factory => :catalog
  end
end
