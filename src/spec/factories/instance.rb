Factory.define :instance do |i|
  i.sequence(:name) { |n| "instance#{n}" }
  i.sequence(:external_key) { |n| "key#{n}" }
  i.hardware_profile_id 1
  i.image_id 1
  i.pool_id 1
  i.state "running"
end
