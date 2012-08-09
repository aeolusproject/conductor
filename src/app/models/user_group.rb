#
#   Copyright 2012 Red Hat, Inc.
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

class UserGroup < ActiveRecord::Base
  class << self
    include CommonFilterMethods
  end
  # name will correspond to the group name if we're using LDAP, otherwise it's
  # entered by the admin creating the group

  # members association is only maintained for local groups
  has_and_belongs_to_many :members, :join_table => "members_user_groups",
                                    :class_name => "User",
                                    :association_foreign_key => "member_id"
  has_one :entity, :as => :entity_target, :dependent => :destroy

  MEMBERSHIP_SOURCE_LDAP = "LDAP"
  MEMBERSHIP_SOURCE_LOCAL = "local"
  MEMBERSHIP_SOURCES = [MEMBERSHIP_SOURCE_LOCAL, MEMBERSHIP_SOURCE_LDAP]

  validates_presence_of :name
  # scope name by membership_source to prevent errors if users are later added
  # to external ldap groups that have the same name as local groups
  validates_uniqueness_of :name, :scope => :membership_source

  validates_presence_of :membership_source
  validates_inclusion_of :membership_source, :in => MEMBERSHIP_SOURCES
  after_save :update_entity

  PRESET_FILTERS_OPTIONS = [
    {:title => "user_groups.preset_filters.local", :id => "local_user_groups", :query => where("user_groups.membership_source = ?", MEMBERSHIP_SOURCE_LOCAL)},
    {:title => "user_groups.preset_filters.ldap", :id => "ldap_user_groups", :query => where("user_groups.membership_source = ?", MEMBERSHIP_SOURCE_LDAP)}
  ]

  def update_entity
    self.entity = Entity.new(:entity_target => self) unless self.entity
    self.entity.name = "#{self.name} (#{self.membership_source})"
    self.entity.save!
  end

  def self.local_groups_active?
    SETTINGS_CONFIG[:groups][:enable_local]
  end

  def self.ldap_groups_active?
    SETTINGS_CONFIG[:groups][:enable_ldap] &&
        SETTINGS_CONFIG[:auth][:strategy] == "ldap"
  end

  def self.active_membership_sources
    sources = []
    sources << MEMBERSHIP_SOURCE_LOCAL if self.local_groups_active?
    sources << MEMBERSHIP_SOURCE_LDAP if self.ldap_groups_active?
    sources
  end

  def self.apply_search_filter(search)
    if search
      where("lower(name) LIKE :search", :search => "%#{search.downcase}%")
    else
      scoped
    end
  end

end
