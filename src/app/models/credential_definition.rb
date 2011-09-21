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
# Table name: credential_definitions
#
#  id               :integer         not null, primary key
#  name             :string(255)
#  label            :string(255)
#  input_type       :string(255)
#  provider_type_id :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class CredentialDefinition < ActiveRecord::Base
  belongs_to :provider_type
  has_many :credentials
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :provider_type_id
  validates_presence_of :label
  validates_presence_of :input_type
  validates_presence_of :provider_type_id
  CREDENTIAL_DEFINITIONS_ORDER = ["username", "password", "account_id", "x509private", "x509public"]
end
