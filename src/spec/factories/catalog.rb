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
  factory :catalog do
    sequence(:name) { |n| "catalog#{n}" }
    association :pool, :factory => :pool
  end

  factory :catalog_with_deployable, :parent => :catalog do |catalog|
    catalog.after_create do |catalog|
      deployable = Factory :deployable
      Factory :catalog_entry, :catalog => catalog, :deployable => deployable
    end
  end
end
