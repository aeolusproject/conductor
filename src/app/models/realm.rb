#
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Realm < ActiveRecord::Base
  has_many :instances
  belongs_to :provider

  validates_presence_of :provider_id

  validates_presence_of :external_key
  validates_uniqueness_of :external_key, :scope => :provider_id

  validates_presence_of :name

  AGGREGATOR_REALM_PROVIDER_DELIMITER = ":"
  AGGREGATOR_REALM_ACCOUNT_DELIMITER = "/"
end
