#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

FactoryGirl.define do

  factory :instance do
    sequence(:name) { |n| "instance#{n}" }
    sequence(:external_key) { |n| "key#{n}" }
    association :hardware_profile, :factory => :mock_hwp1
    association :provider_account, :factory => :mock_provider_account
    association :pool, :factory => :pool
    association :owner, :factory => :user
    state "running"
  end

  factory :instance_with_provider_image, :parent => :instance do
    after_build do |instance|
      #deployment = Factory.build :deployment
      #assembly = deployment.deployable_xml.assemblies[0]
      pimg = FactoryGirl.create(:provider_image, :status => 'COMPLETED')
      instance.image_uuid = pimg.target_image.image_version.base_image.uuid
      instance.image_build_uuid = pimg.target_image.image_version.uuid
      instance.provider_account = pimg.provider_account
      instance.assembly_xml = "<assembly name='frontend' hwp='front_hwp1'>
                                 <image id='#{instance.image_uuid}' build='#{instance.image_build_uuid}'></image>
                               </assembly>"
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

  factory :instance_with_disabled_provider, :parent => :new_instance do
    association :provider_account, :factory => :disabled_provider_account
  end

  factory :instance_in_disabled_pool, :parent => :new_instance do
    association :pool, :factory => :disabled_pool
  end
end
