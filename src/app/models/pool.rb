# == Schema Information
# Schema version: 20110207110131
#
# Table name: pools
#
#  id             :integer         not null, primary key
#  name           :string(255)     not null
#  exported_as    :string(255)
#  quota_id       :integer
#  pool_family_id :integer         not null
#  lock_version   :integer         default(0)
#  created_at     :datetime
#  updated_at     :datetime
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

require 'sunspot_rails'
class Pool < ActiveRecord::Base
  include PermissionedObject
  searchable do
    text :name, :as => :code_substring
  end
  has_many :instances,  :dependent => :destroy
  belongs_to :quota, :autosave => true, :dependent => :destroy
  belongs_to :pool_family

  # NOTE: Commented out because images table doesn't have pool_id foreign key?!
  #has_many :images,  :dependent => :destroy

  validates_presence_of :name
  validates_presence_of :pool_family
  validates_inclusion_of :enabled, :in => [true, false]
  validates_uniqueness_of :name
  validates_uniqueness_of :exported_as, :if => :exported_as
  validates_length_of :name, :maximum => 255

  validates_format_of :name, :with => /^[\w -]*$/n, :message => "must only contain: numbers, letters, spaces, '_' and '-'"

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  before_destroy :destroyable?

  def cloud_accounts
    accounts = []
    instances.each do |instance|
      if instance.provider_account and !accounts.include?(instance.provider_account)
        accounts << instance.provider_account
      end
    end
  end

  def destroyable?
    instances.all? {|i| i.destroyable? }
  end

end
