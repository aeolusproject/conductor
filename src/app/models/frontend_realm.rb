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
# Table name: frontend_realms
#
#  id           :integer         not null, primary key
#  name         :string(1024)    not null
#  lock_version :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class FrontendRealm < ActiveRecord::Base
  class << self
    include CommonFilterMethods
  end
  has_many :realm_backend_targets, :dependent => :destroy
  has_many :instances

  # there is a problem with has_many through + polymophic in AR:
  # http://blog.hasmanythrough.com/2006/4/3/polymorphic-through
  # so we define explicitly backend_realms and backend_providers
  has_many :backend_realms, :through => :realm_backend_targets, :source => :realm, :conditions => "realm_backend_targets.realm_or_provider_type = 'Realm'"
  has_many :backend_providers, :through => :realm_backend_targets, :source => :provider, :conditions => "realm_backend_targets.realm_or_provider_type = 'Provider'"

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_length_of :description, :maximum => 255, :allow_blank => true

  PRESET_FILTERS_OPTIONS = []

  private

  def self.apply_search_filter(search)
    if search
      where("lower(frontend_realms.name) LIKE :search", :search => "%#{search.downcase}%")
    else
      scoped
    end
  end
end
