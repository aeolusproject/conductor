Factory.define :instance do |i|
  i.sequence(:name) { |n| "instance#{n}" }
  i.sequence(:external_key) { |n| "key#{n}" }
  i.hardware_profile_id 1
  i.image_id 1
  i.pool_id 1
  i.state "running"
end

Factory.define :pending_instance, :parent => :instance do |i|
  i.state Instance::STATE_PENDING
end

Factory.define :new_instance, :parent => :instance do |i|
  i.state Instance::STATE_NEW
end