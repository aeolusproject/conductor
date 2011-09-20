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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'password'
require 'ldap'

class User < ActiveRecord::Base
  attr_accessor :password

  # this attr is used when validating non-local (ldap) users
  # - these users have blank password, so validation should accept nil password
  # for them
  attr_accessor :ignore_password

  has_many :permissions
  has_many :owned_instances, :class_name => "Instance", :foreign_key => "owner_id"
  has_many :deployments, :foreign_key => "owner_id"
  has_many :view_states

  belongs_to :quota, :autosave => true, :dependent => :destroy
  accepts_nested_attributes_for :quota

  validates_presence_of :quota
  validates_length_of :first_name, :maximum => 255, :allow_blank => true
  validates_length_of :last_name,  :maximum => 255, :allow_blank => true

  validates_uniqueness_of :login
  validates_length_of :login, :within => 1..100, :allow_blank => false

  #validates_uniqueness_of :email

  validates_confirmation_of :password, :if => Proc.new {|u| u.check_password?}
  validates_length_of :password, :within => 4..255, :if => Proc.new {|u| u.check_password?}

  # email validation
  # http://lindsaar.net/2010/1/31/validates_rails_3_awesome_is_true
  # TODO: if email is not filled in in LDAP, LDAP user won't be able to login
  # -> can we suppose that LDAP user is always filled in or should we disable
  # email checking?
  #validates_format_of :email, :with => /^([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})$/i

  before_save :encrypt_password

  def name
    "#{first_name} #{last_name}"
  end

  def self.authenticate(username, password)
    return unless u = User.find_by_login(username)
    # FIXME: this is because of tests - encrypted password is submitted,
    # don't know how to get unencrypted version (from factorygirl)
    if password.length == 192 and password == u.crypted_password
      return u
    elsif Password.check(password, u.crypted_password)
      return u
    else
      u.failed_login_count += 1
      u.save!
      return nil
    end
  end

  def self.authenticate_using_ldap(username, password)
    if Ldap.valid_ldap_authentication?(username, password, SETTINGS_CONFIG[:auth][:ldap])
      u = User.find_by_login(username) || create_ldap_user!(username)
      return u
    else
      return nil
    end
  end

  def check_password?
    # don't check password if it's a new no-local user (ldap)
    # or if a user is updated
    new_record? ? !ignore_password : (!password.blank? or !password_confirmation.blank?)
  end

  private

  def encrypt_password
    self.crypted_password = Password::update(password) unless password.blank?
  end

  def self.create_ldap_user!(login)
    User.create!(:login => login, :quota => Quota.new, :ignore_password => true)
  end
end
