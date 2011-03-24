Factory.define :instance do |i|
  i.sequence(:name) { |n| "instance#{n}" }
  i.sequence(:external_key) { |n| "key#{n}" }
  i.association :hardware_profile, :factory => :mock_hwp1
  i.provider_account { Factory.build(:mock_provider_account) }
  i.association :template, :factory => :template
  i.association :pool, :factory => :pool
  i.association :owner, :factory => :user
  i.state "running"
end

Factory.define :other_owner_instance, :parent => :instance do |i|
  i.association :owner, :factory => :other_named_user
end

Factory.define :mock_running_instance, :parent => :instance do |i|
  i.instance_key { |k| k.association(:mock_instance_key)}
end

Factory.define :mock_pending_instance, :parent => :instance do |i|
  i.state Instance::STATE_PENDING
end

Factory.define :new_instance, :parent => :instance do |i|
  i.state Instance::STATE_NEW
end

Factory.define :ec2_instance, :parent => :instance do |i|
  i.association :hardware_profile, :factory => :ec2_hwp1
  i.association :provider_account, :factory => :ec2_provider_account
  i.association :instance_key, :factory => :ec2_instance_key1
end
