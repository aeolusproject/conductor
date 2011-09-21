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

  factory :user do |u|
    sequence(:login) { |n| "user#{n}" }
    password 'secret'
    password_confirmation 'secret'
    first_name 'John'
    last_name 'Smith'
    association :quota
    after_build { |u| u.email ||= "#{u.login}@example.com" }
  end

  factory :other_named_user, :parent => :user do
    first_name 'Jane'
    last_name 'Doe'
  end

  factory :tuser, :parent => :user do
  end

  factory :admin_user, :parent => :user do
    login 'admin'
  end

  factory :pool_creator_user, :parent => :user do
  end

  factory :provider_admin_user, :parent => :user do
  end

  factory :pool_user, :parent => :user do
    sequence(:login) { |n| "pool_user#{n}" }
  end

  factory :pool_user2, :parent => :user do
    sequence(:login) { |n| "pool_user2#{n}" }
  end

end
