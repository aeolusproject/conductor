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

  factory :hardware_profile_property do
  end

  factory :mock_hwp1_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 12288
  end

  factory :mock_hwp1_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 4096
  end

  factory :mock_hwp1_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 4
  end

  factory :mock_hwp1_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :mock_hwp2_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'range'
    unit 'MB'
    value 10240
    range_first 7680
    range_last 15360
  end

  factory :mock_hwp2_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'enum'
    unit 'GB'
    value 850
  #  p.property_enum_entries { |p| [p.association(:mock_hwp2_storage_enum1),
  #                                association(:mock_hwp2_storage_enum2)] }
  end

  factory :mock_hwp2_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 2
  end

  factory :mock_hwp2_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :mock_hwp_fake_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1740.8
  end

  factory :mock_hwp_fake_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 160
  end

  factory :mock_hwp_fake_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1
  end

  factory :mock_hwp_fake_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :front_hwp1_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1
  end

  factory :front_hwp1_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 1
  end

  factory :front_hwp1_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1
  end

  factory :front_hwp1_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :front_hwp2_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1024
  end

  factory :front_hwp2_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 2
  end

  factory :front_hwp2_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1
  end

  factory :front_hwp2_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end


  # EC2 Profiles:


  factory :ec2_hwp1_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1740.8
  end

  factory :ec2_hwp1_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 160
  end

  factory :ec2_hwp1_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1
  end

  factory :ec2_hwp1_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :front_hwp3_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1740.8
  end

  factory :front_hwp3_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 3
  end

  factory :front_hwp3_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1
  end

  factory :front_hwp3_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :hwpp_range, :parent => :hardware_profile_property do
    name 'memory'
    kind 'range'
    unit 'MB'
    range_first 256
    range_last 512
    value 256
  end

  factory :hwpp_fixed, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 256
  end

  factory :hwpp_enum, :parent => :hardware_profile_property do
    name 'memory'
    kind 'enum'
    unit 'MB'
    value 256
  end

  factory :hwpp_arch, :parent => :hardware_profile_property do
    name 'architecture'
    kind 'fixed'
    unit 'label'
    value 'x86_64'
  end

  factory :hwpp_ranged_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'range'
    unit 'count'
    range_first 1
    range_last 32
    value 2
  end

  factory :hwpp_nil_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value nil
  end

  factory :hwpp_nil_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'enum'
    unit 'GB'
    value nil
  end

  factory :hwpp_float_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1.0
  end

end
