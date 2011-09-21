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

  factory :realm do
    sequence(:name) { |n| "realm#{n}" }
    sequence(:external_key) { |n| "key#{n}" }
    association(:provider)
  end

  factory :realm1, :parent => :realm do
  end

  factory :realm2, :parent => :realm do
  end

  factory :realm3, :parent => :realm do
  end

  factory :realm4, :parent => :realm do
  end

  factory :backend_realm, :parent => :realm do
    name 'backend_name'
    external_key 'backend_key'
  end

end
