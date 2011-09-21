#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

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

  factory :instance_with_disabled_provider, :parent => :new_instance do
    association :provider_account, :factory => :disabled_provider_account
  end

  factory :instance_in_disabled_pool, :parent => :new_instance do
    association :pool, :factory => :disabled_pool
  end

end
