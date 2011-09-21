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
# Schema version: 20110309105149
#
# Table name: credentials
#
#  id                       :integer         not null, primary key
#  provider_account_id      :integer
#  value                    :text
#  credential_definition_id :integer         not null
#  created_at               :datetime
#  updated_at               :datetime
#

class Credential < ActiveRecord::Base

  belongs_to :provider_account
  belongs_to :credential_definition
  validates_presence_of :credential_definition_id
  validates_presence_of :value
  validates_uniqueness_of :credential_definition_id, :scope => :provider_account_id
end
