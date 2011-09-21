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

  factory :provider_type do
    sequence(:name) { |n| "name#{n}" }
    sequence(:deltacloud_driver) { |n| "deltacloud_driver#{n}" }
  end

  factory :mock_provider_type, :parent => :provider_type do
    name 'Mock'
    deltacloud_driver 'mock'
  end

  factory :ec2_provider_type, :parent => :provider_type do
    name 'Amazon EC2'
    deltacloud_driver 'ec2'
  end

end
