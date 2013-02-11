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
# Schema version: 20110207110131
#
# Table name: users
#
#  id                  :integer         not null, primary key
#  username            :string(255)     not null
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

  class << self
    include CommonFilterMethods
  end

  before_destroy :ensure_not_running_any_instances

  has_many :permissions, :through => :entity
  has_many :derived_permissions, :through => :entity
  has_many :owned_instances, :class_name => "Instance", :foreign_key => "owner_id"
  has_many :deployments, :foreign_key => "owner_id"
  has_many :view_states
  has_and_belongs_to_many :user_groups, :join_table => "members_user_groups",
                          :foreign_key => "member_id"
  has_one :entity, :as => :entity_target, :dependent => :destroy
  has_many :session_entities, :dependent => :destroy
  belongs_to :quota, :autosave => true, :dependent => :destroy
  has_many :base_images, :class_name => "Tim::BaseImage"

  attr_accessor :password
  # this attr is used when validating non-local (ldap) users
  # - these users have blank password, so validation should accept nil password
  # for them
  attr_accessor :ignore_password
  accepts_nested_attributes_for :quota

  before_validation :strip_whitespace
  before_save :encrypt_password
  after_save :update_entity

  validates :email, :presence => true,
                    :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i },
                    :if => Proc.new { |u| u.local_user? }
  validates :username, :presence => true,
                       :length => { :within => 1..100 },
                       :uniqueness => true
  validates :first_name, :length => { :maximum => 255 }
  validates :last_name, :length => { :maximum => 255 }
  validates :password, :presence => true,
                       :length => { :within => 4..255 },
                       :confirmation => true,
                       :if => Proc.new { |u| u.check_password? }
  validates :quota, :presence => true
  validate :validate_ldap_changes,
           :if => Proc.new { |user| !user.new_record? && SETTINGS_CONFIG[:auth][:strategy] == "ldap" }

  def name
    "#{first_name} #{last_name}".strip
  end

  def self.authenticate(username, password, ipaddress)
    username = username.strip unless username.nil?
    return unless u = User.find_by_username(username)
    # FIXME: this is because of tests - encrypted password is submitted,
    # don't know how to get unencrypted version (from factorygirl)
    if password.length == 192 and password == u.crypted_password
      update_login_attributes(u, ipaddress)
    elsif Password.check(password, u.crypted_password)
      update_login_attributes(u, ipaddress)
    else
      u.failed_login_count += 1
      u.save!
      u = nil
    end
    u.save! unless u.nil?
    return u
  end

  def self.authenticate_using_ldap(username, password, ipaddress)
    if Ldap.valid_ldap_authentication?(username, password)
      u = User.find_by_username(username) || create_ldap_user!(username)
      update_login_attributes(u, ipaddress)
    else
      u = User.find_by_username(username)
      if u.present?
        u.failed_login_count += 1
        u.save!
      end
      u = nil
    end
    u.save! unless u.nil?
    return u
  end

  def self.authenticate_using_krb(username, ipaddress)
    u = User.find_by_username(username) || create_krb_user!(username)
    update_login_attributes(u, ipaddress)
    u.save!
    u
  end

  def self.update_login_attributes(u, ipaddress)
    u.login_count += 1
    u.last_login_ip = ipaddress
    u.last_login_at = DateTime.now
  end

  def check_password?
    # don't check password if it's a new no-local user (ldap)
    # or if a user is updated
    new_record? ? !ignore_password : !(password.blank? && password_confirmation.blank?)
  end

  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.delay.password_reset(self.id)
  end

  def local_user?
    new_record? ? !ignore_password : (!crypted_password.blank?)
  end

  PRESET_FILTERS_OPTIONS = []

  def all_groups
    group_list = []
    group_list += self.user_groups if UserGroup.local_groups_active?
    if UserGroup.ldap_groups_active?
      ldap_group_names = Ldap.ldap_groups(self.username)
      ldap_group_names.each do |group_name|
        ldap_group = UserGroup.find_by_name_and_membership_source(
            group_name, UserGroup::MEMBERSHIP_SOURCE_LDAP)
        if ldap_group
          # update  group on each login so we can later check/purge groups
          # that haven't been updated lately (i.e. no recent logins by users
          # that belong to them)
          ldap_group.touch
        else
          ldap_group = UserGroup.create!(:name => group_name,
                                         :membership_source =>
                                           UserGroup::MEMBERSHIP_SOURCE_LDAP)
        end
        group_list << ldap_group
      end
    end
    group_list
  end

  private

  def self.apply_search_filter(search)
    if search
      where("lower(first_name) LIKE :search OR lower(last_name) LIKE :search OR lower(username) LIKE :search OR lower(email) LIKE :search", :search => "%#{search.downcase}%")
    else
      scoped
    end
  end

  def validate_ldap_changes
    if self.first_name_changed? || self.last_name_changed? || self.email_changed? ||
        self.username_changed? || self.crypted_password_changed? then
      errors.add(:base, _('Cannot edit LDAP user'))
    end
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  def encrypt_password
    self.crypted_password = Password::update(password) unless password.blank?
  end

  def self.create_ldap_user!(username)
    User.create!(:username => username, :quota => Quota.new_for_user, :ignore_password => true)
  end

  def self.create_krb_user!(username)
    User.create!(:username => username, :quota => Quota.new_for_user, :ignore_password => true)
  end

  def ensure_not_running_any_instances
    raise _('%s has running instances') % username if deployments.any?{ |deployment| deployment.any_instance_running? }
  end

  def strip_whitespace
    self.username = self.username.strip unless self.username.nil?
  end

  def update_entity
    self.entity = Entity.new(:entity_target => self) unless self.entity
    self.entity.name = "#{self.first_name} #{self.last_name} (#{self.username})"
    self.entity.save!
  end
end
