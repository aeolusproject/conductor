# == Schema Information
# Schema version: 20110207110131
#
# Table name: users
#
#  id                  :integer         not null, primary key
#  login               :string(255)     not null
#  email               :string(255)     not null
#  crypted_password    :string(255)     not null
#  password_salt       :string(255)     not null
#  persistence_token   :string(255)     not null
#  single_access_token :string(255)     not null
#  perishable_token    :string(255)     not null
#  first_name          :string(255)
#  last_name           :string(255)
#  quota_id            :integer
#  login_count         :integer         default(0), not null
#  failed_login_count  :integer         default(0), not null
#  last_request_at     :datetime
#  current_login_at    :datetime
#  last_login_at       :datetime
#  current_login_ip    :string(255)
#  last_login_ip       :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#

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

class User < ActiveRecord::Base
  acts_as_authentic

  has_many :permissions
  has_many :owned_instances, :class_name => "Instance", :foreign_key => "owner_id"
  has_many :deployments, :foreign_key => "owner_id"
  has_many :view_states

  belongs_to :quota, :autosave => true, :dependent => :destroy
  accepts_nested_attributes_for :quota

  validates_presence_of :quota
  validates_length_of :first_name, :maximum => 255, :allow_blank => true
  validates_length_of :last_name,  :maximum => 255, :allow_blank => true

  # authlogic's password confirmation doesn't fire up when we fill in the
  # confirmation field but leave the password field blank. We have to check
  # that manually:
  validates_confirmation_of :password, :if => "password.blank? and !password_confirmation.blank?"

  def name
    "#{first_name} #{last_name}"
  end
end
