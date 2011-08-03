FactoryGirl.define do
  factory :view_state do
    sequence(:name) { |n| "view-state#{n}" }
    controller 'pools'
    action 'view'
    state("sort-column" => "name", "sort-order" => "desc", "columns" => ["name", "deployments", "instances"])
    association :user
  end
end
