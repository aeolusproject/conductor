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
  belongs_to :pool_family
  has_many :catalog_entries, :dependent => :destroy
  has_many :deployables, :through => :catalog_entries
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  before_destroy :destroy_deployables_related_only_to_self
  before_create :set_pool_family

  validates_presence_of :pool
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 1024

  def object_list
    super + [pool, pool_family]
  end
  class << self
    alias orig_list_for_user_include list_for_user_include
    alias orig_list_for_user_conditions list_for_user_conditions
  end

  def self.list_for_user_include
    orig_list_for_user_include + [ {:pool => :permissions},
                                   {:pool_family => :permissions} ]
  end

  def self.list_for_user_conditions
    "(#{orig_list_for_user_conditions}) or
     (permissions_pools.user_id=:user and
      permissions_pools.role_id in (:role_ids)) or
     (permissions_pool_families.user_id=:user and
      permissions_pool_families.role_id in (:role_ids))"
  end

  PRESET_FILTERS_OPTIONS = [
    {:title => "catalogs.preset_filters.belongs_to_default_pool", :id => "belongs_to_default_pool", :query => includes(:pool).where("pools.name" => "Default")}
  ]

  def destroy_deployables_related_only_to_self
    deployables.each {|d| d.destroy if d.catalogs.count == 1}
  end

  def set_pool_family
    self[:pool_family_id] = pool.pool_family_id
  end

  private

  def self.apply_search_filter(search)
    if search
      includes(:pool).where("lower(catalogs.name) LIKE :search OR lower(pools.name) LIKE :search", :search => "%#{search.downcase}%")
    else
      scoped
    end
  end

end
