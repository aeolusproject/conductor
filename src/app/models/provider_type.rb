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
# Table name: provider_types
#
#  id              :integer         not null, primary key
#  name            :string(255)     not null
#  codename        :string(255)     not null
#  ssh_user        :string(255)
#  home_dir        :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

class ProviderType < ActiveRecord::Base

  has_many :providers
  has_many :credential_definitions, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :deltacloud_driver
  validates_uniqueness_of :deltacloud_driver

  def provider_accounts_for_user(user)
    providers = Provider.list_for_user(user, Privilege::VIEW).where(:provider_type_id => self.id)
    providers.inject([]) {|all, p| all += ProviderAccount.list_for_user(user, Privilege::VIEW).where(:provider_id => p.id)}
  end
end
