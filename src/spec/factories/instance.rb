Factory.define :instance do |i|
  i.sequence(:name) { |n| "instance#{n}" }
  i.sequence(:external_key) { |n| "key#{n}" }
  i.association :hardware_profile, :factory => :mock_hwp1
  i.association :cloud_account, :factory => :mock_cloud_account
  i.association :image, :factory => :image
  i.association :pool, :factory => :pool
  i.association :owner, :factory => :user
  i.state "running"
end

Factory.define :pending_instance, :parent => :instance do |i|
  i.state Instance::STATE_PENDING
end

Factory.define :new_instance, :parent => :instance do |i|
  i.state Instance::STATE_NEW
end
