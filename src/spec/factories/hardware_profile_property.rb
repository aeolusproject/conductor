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

  factory :hardware_profile_property do
  end

  factory :mock_hwp1_memory, :parent => :hardware_profile_property do
    name 'memory'
    kind 'fixed'
    unit 'MB'
    value 1740.8
  end

  factory :mock_hwp1_storage, :parent => :hardware_profile_property do
    name 'storage'
    kind 'fixed'
    unit 'GB'
    value 160
  end

  factory :mock_hwp1_cpu, :parent => :hardware_profile_property do
    name 'cpu'
    kind 'fixed'
    unit 'count'
    value 1.0
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
    value 2.0
  end

  factory :mock_hwp2_arch, :parent => :hardware_profile_property do
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
    value 1.0
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

end
