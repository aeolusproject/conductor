Factory.define :deployment do |d|
  d.sequence(:name) { |n| "deployment#{n}" }
  d.association :deployable, :factory => :deployable
  d.association :pool, :factory => :pool
  d.association :owner, :factory => :user
end
