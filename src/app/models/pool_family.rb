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
# Schema version: 20110603204130
#
# Table name: pool_families
#
#  id           :integer         not null, primary key
#  name         :string(255)     not null
#  description  :string(255)
#  lock_version :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#  quota_id     :integer
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class PoolFamily < ActiveRecord::Base
  include PermissionedObject
  DEFAULT_POOL_FAMILY_KEY = "default_pool_family"

  has_many :pools,  :dependent => :destroy
  belongs_to :quota, :dependent => :destroy
  accepts_nested_attributes_for :quota
  has_and_belongs_to_many :provider_accounts, :uniq => true
  has_many :permissions, :as => :permission_object, :dependent => :destroy

  validates_length_of :name, :maximum => 255
  validates_format_of :name, :with => /^[\w -]*$/n, :message => "must only contain: numbers, letters, spaces, '_' and '-'"

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :quota

  before_destroy :destroyable?

  def self.default
    MetadataObject.lookup(DEFAULT_POOL_FAMILY_KEY)
  end

  def set_as_default
    MetadataObject.set(DEFAULT_POOL_FAMILY_KEY, self)
  end

  def destroyable?
    # A PoolFamily is destroyable unless it is the default PoolFamily
    self != PoolFamily.default
  end

  def all_providers_disabled?
    !provider_accounts.empty? and !provider_accounts.any? {|acc| acc.provider.enabled?}
  end
end
