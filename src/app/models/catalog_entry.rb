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
# Table name: catalog_entries
#
#  id          :integer         not null, primary key
#  name        :string(1024)    not null
#  description :text            not null
#  url         :string(255)
#  owner_id    :integer
#  catalog_id  :integer         not null
#

class CatalogEntry < ActiveRecord::Base

  belongs_to :catalog
  belongs_to :deployable

  validates_presence_of :catalog
  validates_presence_of :deployable

  # This probably goes away once we separate catalog entry creation from deployables
  accepts_nested_attributes_for :deployable
end
