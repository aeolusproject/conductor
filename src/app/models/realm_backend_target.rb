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
# Schema version: 20110207110131
#
# Table name: realm_backend_targets
#
#  id                     :integer         not null, primary key
#  realm_or_provider_id   :integer         not null
#  realm_or_provider_type :string(255)     not null
#  frontend_realm_id      :integer         not null
#

class RealmBackendTarget < ActiveRecord::Base
  belongs_to :frontend_realm
  belongs_to :realm_or_provider, :polymorphic =>true
  belongs_to :realm,  :class_name => 'Realm', :foreign_key => 'realm_or_provider_id'
  belongs_to :provider,  :class_name => 'Provider', :foreign_key => 'realm_or_provider_id'

  validates_uniqueness_of :frontend_realm_id, :scope => [:realm_or_provider_id, :realm_or_provider_type]
  validates_presence_of :realm_or_provider

  def target_realm
    (realm_or_provider_type == "Realm") ? realm : nil
  end

  def target_provider
    (realm_or_provider_type == "Realm") ? realm.provider : provider
  end
end
