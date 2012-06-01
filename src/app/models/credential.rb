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
# Table name: credentials
#
#  id                       :integer         not null, primary key
#  provider_account_id      :integer
#  value                    :text
#  credential_definition_id :integer         not null
#  created_at               :datetime
#  updated_at               :datetime
#

class Credential < ActiveRecord::Base

  belongs_to :provider_account
  belongs_to :credential_definition
  validates_presence_of :credential_definition_id
  validates_presence_of :value
  validates_uniqueness_of :credential_definition_id, :scope => :provider_account_id

  attr_protected :id, :provider_account_id, :created_at
  attr_accessible :value, :credential_definition_id
end
