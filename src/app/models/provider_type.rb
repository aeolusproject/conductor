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

# == Schema Information
# Schema version: 20110309105149
#
# Table name: provider_types
#
#  id              :integer         not null, primary key
#  name            :string(255)     not null
#  codename        :string(255)     not null
#  ssh_user        :string(255)
#  home_dir        :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

class ProviderType < ActiveRecord::Base

  has_many :providers
  has_many :credential_definitions, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :deltacloud_driver
  validates_uniqueness_of :deltacloud_driver
end
