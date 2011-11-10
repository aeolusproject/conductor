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
  include PermissionedObject

  belongs_to :pool
  has_many :catalog_entries, :dependent => :destroy
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  validates_presence_of :pool
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 1024

  PRESET_FILTERS_OPTIONS = [
    {:title => I18n.t("catalogs.preset_filters.belongs_to_default_pool"), :id => "belongs_to_default_pool", :query => includes(:pool).where("pools.name" => "Default")}
  ]

  def self.apply_filters(options = {})
    apply_preset_filter(options[:preset_filter_id]).apply_search_filter(options[:search_filter])
  end

  private

  def self.apply_preset_filter(preset_filter_id)
    if preset_filter_id.present?
      PRESET_FILTERS_OPTIONS.select{|item| item[:id] == preset_filter_id}.first[:query]
    else
      scoped
    end
  end

  def self.apply_search_filter(search)
    if search
      includes(:pool).where("catalogs.name ILIKE :search OR pools.name ILIKE :search", :search => "%#{search}%")
    else
      scoped
    end
  end

end
