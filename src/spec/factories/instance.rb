FactoryGirl.define do

  factory :instance do
    sequence(:name) { |n| "instance#{n}" }
    sequence(:external_key) { |n| "key#{n}" }
    association :hardware_profile, :factory => :mock_hwp1
    association :provider_account, :factory => :mock_provider_account
    association :pool, :factory => :pool
    association :owner, :factory => :user
    state "running"
    after_build do |instance|
      deployment = Factory.build :deployment
      assembly = deployment.deployable_xml.assemblies[0]
      instance.image_uuid = assembly.image_id
      instance.image_build_uuid = assembly.image_build
      instance.assembly_xml = assembly.to_s
    end
  end

  factory :other_owner_instance, :parent => :instance do
    association :owner, :factory => :other_named_user
  end

  factory :mock_running_instance, :parent => :instance do
    instance_key { |k| k.association(:mock_instance_key)}
  end

  factory :mock_pending_instance, :parent => :instance do
    state Instance::STATE_PENDING
  end

  factory :new_instance, :parent => :instance do
    state Instance::STATE_NEW
  end

  factory :ec2_instance, :parent => :instance do
    association :hardware_profile, :factory => :ec2_hwp1
    association :provider_account, :factory => :ec2_provider_account
    association :instance_key, :factory => :ec2_instance_key1
  end

end
