# == Schema Information
# Schema version: 20110207110131
#
# Table name: roles
#
#  id              :integer         not null, primary key
#  name            :string(255)     not null
#  scope           :string(255)     not null
#  lock_version    :integer         default(0)
#  created_at      :datetime
#  updated_at      :datetime
#  assign_to_owner :boolean
#

#
# Copyright (C) 2009 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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

require 'sunspot_rails'
class Role < ActiveRecord::Base
  searchable do
    text :name, :as => :code_substring
  end
  has_many :permissions, :dependent => :destroy
  has_many :privileges, :dependent => :destroy

  validates_presence_of :scope
  validates_presence_of :name
  validates_uniqueness_of :name

  validates_associated :privileges

  validates_length_of :name, :maximum => 255
end
