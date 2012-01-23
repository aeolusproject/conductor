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
# Table name: realms
#
#  id           :integer         not null, primary key
#  external_key :string(255)     not null
#  name         :string(1024)    not null
#  provider_id  :integer
#  lock_version :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Realm < ActiveRecord::Base
  class << self
    include CommonFilterMethods
  end
  belongs_to :provider
  has_and_belongs_to_many :provider_accounts, :uniq => true

  has_many :realm_backend_targets, :as => :realm_or_provider, :dependent => :destroy
  has_many :frontend_realms, :through => :realm_backend_targets

  validates_presence_of :external_key
  validates_uniqueness_of :external_key, :scope => :provider_id

  validates_presence_of :name
  validates_presence_of :provider_id

  CONDUCTOR_REALM_PROVIDER_DELIMITER = ":"
  CONDUCTOR_REALM_ACCOUNT_DELIMITER = "/"
  PRESET_FILTERS_OPTIONS = []

  def name_with_provider
    "#{self.provider.name}: #{self.name}"
  end

  # Run through all providers and try to find provider accounts
  # This may be rather slow as it must query deltacloud for each provider
  def self.scan_for_new
    providers = Provider.all(:include => :provider_accounts)
    providers.each do |provider|
      provider.populate_realms
    end
    true
  end

  private

  def self.apply_search_filter(search)
    if search
      where("lower(name) LIKE :search", :search => "%#{search.downcase}%")
    else
      scoped
    end
  end
end
