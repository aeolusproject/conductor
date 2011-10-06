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

  factory :hardware_profile do
    sequence(:name) { |n| "hardware_profile#{n}" }
    sequence(:external_key) { |n| "hardware_profile_key#{n}" }
  end

  factory :mock_hwp1, :parent => :hardware_profile do
    memory { |p| p.association(:mock_hwp1_memory) }
    storage { |p| p.association(:mock_hwp1_storage) }
    cpu { |p| p.association(:mock_hwp1_cpu) }
    architecture { |p| p.association(:mock_hwp1_arch) }
    sequence(:external_key) { |n| "m1-small" }
  end

  factory :mock_hwp2, :parent => :hardware_profile do
    memory { |p| p.association(:mock_hwp2_memory) }
    storage { |p| p.association(:mock_hwp2_storage) }
    cpu { |p| p.association(:mock_hwp2_cpu) }
    architecture { |p| p.association(:mock_hwp2_arch) }
    external_key 'm1-large'
  end

  factory :mock_hwp_fake, :parent => :hardware_profile do
    memory { |p| p.association(:mock_hwp_fake_memory) }
    storage { |p| p.association(:mock_hwp_fake_storage) }
    cpu { |p| p.association(:mock_hwp_fake_cpu) }
    architecture { |p| p.association(:mock_hwp_fake_arch) }
    sequence(:external_key) { |n| "mock_hwp_fake_key#{n}" }
  end

  factory :front_hwp1, :parent => :hardware_profile do
    memory { |p| p.association(:front_hwp1_memory) }
    storage { |p| p.association(:front_hwp1_storage) }
    cpu { |p| p.association(:front_hwp1_cpu) }
    architecture { |p| p.association(:front_hwp1_arch) }
    name 'front_hwp1'
    external_key 'front_hwp1_key'
  end

  factory :front_hwp2, :parent => :hardware_profile do
    memory { |p| p.association(:front_hwp2_memory) }
    storage { |p| p.association(:front_hwp2_storage) }
    cpu { |p| p.association(:front_hwp2_cpu) }
    architecture { |p| p.association(:front_hwp2_arch) }
    name 'front_hwp2'
    external_key 'front_hwp2_key'
  end


  factory :ec2_hwp1, :parent => :hardware_profile do
    memory { |p| p.association(:ec2_hwp1_memory) }
    storage { |p| p.association(:ec2_hwp1_storage) }
    cpu { |p| p.association(:ec2_hwp1_cpu) }
    architecture { |p| p.association(:ec2_hwp1_arch) }
    sequence(:external_key) { |n| "ec2_hwp1_key#{n}" }
  end

  factory :front_hwp3, :parent => :hardware_profile do
    memory { |p| p.association(:front_hwp3_memory) }
    storage { |p| p.association(:front_hwp3_storage) }
    cpu { |p| p.association(:front_hwp3_cpu) }
    architecture { |p| p.association(:front_hwp3_arch) }
    name 'front_hwp3'
    external_key 'front_hwp3_key'
  end

  factory :back_hwp_ranged_cpu, :parent => :hardware_profile do
    memory { |p| p.association(:front_hwp1_memory) }
    storage { |p| p.association(:front_hwp1_storage) }
    cpu { |p| p.association(:hwpp_ranged_cpu) }
    architecture { |p| p.association(:front_hwp1_arch) }
    name 'cpu_range'
    external_key 'cpu_range'
  end

  factory :front_end_nil_cpu, :parent => :hardware_profile do
    memory { |p| p.association(:front_hwp3_memory) }
    storage { |p| p.association(:front_hwp3_storage) }
    cpu { |p| p.association(:hwpp_nil_cpu) }
    architecture { |p| p.association(:front_hwp3_arch) }
    name 'front_nil_cpu'
    external_key 'front_nil_cpu'
  end

  factory :front_end_nil_storage, :parent => :hardware_profile do
    memory { |p| p.association(:front_hwp3_memory) }
    storage { |p| p.association(:hwpp_nil_storage) }
    cpu { |p| p.association(:front_hwp1_cpu) }
    architecture { |p| p.association(:front_hwp3_arch) }
    name 'front_nil_storage'
    external_key 'front_nil_storage'
  end

  factory :front_end_with_floats, :parent => :hardware_profile do
    memory { |p| p.association(:front_hwp3_memory) }
    storage { |p| p.association(:front_hwp3_storage) }
    cpu { |p| p.association(:hwpp_float_cpu) }
    architecture { |p| p.association(:front_hwp3_arch) }
    name 'front_float_cpu'
    external_key 'front_float_cpu'
  end

end
