Factory.define :suggested_deployable do |d|
  d.sequence(:name) { |n| "suggested_deployable#{n}" }
  d.url "http://url_to_deployable"
  d.description "suggested deployable description"
  d.association :owner, :factory => :user
end
