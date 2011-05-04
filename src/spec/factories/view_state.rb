Factory.define :view_state do |vs|
  vs.sequence(:name) { |n| "view-state#{n}" }
  vs.controller 'pools'
  vs.action 'view'
  vs.state({"sort-column" => "name", "sort-order" => "desc",
                          "columns" => ["name", "deployments", "instances"]})
  vs.association :user
end
