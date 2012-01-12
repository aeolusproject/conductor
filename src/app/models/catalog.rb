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
#
# Table name: catalogs
#
#  id         :integer         not null, primary key
#  pool_id    :integer
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Catalog < ActiveRecord::Base
  class << self
    include CommonFilterMethods
  end
  include PermissionedObject

  belongs_to :pool
  has_many :catalog_entries, :dependent => :destroy
  has_many :deployables, :through => :catalog_entries
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  before_destroy :check_deployable_references

  validates_presence_of :pool
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 1024

  PRESET_FILTERS_OPTIONS = [
    {:title => I18n.t("catalogs.preset_filters.belongs_to_default_pool"), :id => "belongs_to_default_pool", :query => includes(:pool).where("pools.name" => "Default")}
  ]
  def check_deployable_references
    return true if deployables.empty?
    !(deployables.any? {|d| d.catalogs.count == 1})
  end

  private

  def self.apply_search_filter(search)
    if search
      includes(:pool).where("catalogs.name ILIKE :search OR pools.name ILIKE :search", :search => "%#{search}%")
    else
      scoped
    end
  end

end
