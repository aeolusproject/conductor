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

  factory :provider do
    sequence(:name) { |n| "provider#{n}" }
    provider_type { Factory.build :provider_type }
    url { |p| "http://www." + p.name + ".com/api" }
  end

  factory :mock_provider, :parent => :provider do
    provider_type {ProviderType.find_by_deltacloud_driver("mock")}
    url 'http://localhost:3002/api'
    hardware_profiles { |hp| [hp.association(:mock_hwp1), hp.association(:mock_hwp2)] }
    after_create { |p| p.realms << FactoryGirl.create(:realm1, :provider => p) << FactoryGirl.create(:realm2, :provider => p) }
  end

  factory :mock_provider2, :parent => :provider do
    name 'mock2'
    provider_type { ProviderType.find_by_deltacloud_driver("mock") }
    url 'http://localhost:3002/api'
    deltacloud_provider 'mock'
    after_create { |p| p.realms << FactoryGirl.create(:realm3, :provider => p) }
  end

  factory :ec2_provider, :parent => :provider do
    name 'amazon-ec2'
    provider_type { ProviderType.find_by_deltacloud_driver("ec2") }
    url 'http://localhost:3002/api'
    deltacloud_provider 'ec2-us-east-1'
    hardware_profiles { |hp| [hp.association(:ec2_hwp1)] }
    after_create { |p| p.realms << FactoryGirl.create(:realm4, :provider => p) }
  end

  factory :disabled_provider, :parent => :mock_provider do
    enabled false
  end

end
