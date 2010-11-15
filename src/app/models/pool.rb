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

class Pool < ActiveRecord::Base
  include PermissionedObject
  has_many :instances,  :dependent => :destroy
  belongs_to :quota
  belongs_to :zone

  has_many :images,  :dependent => :destroy
  has_many :hardware_profiles,  :dependent => :destroy



  validates_presence_of :name
  validates_presence_of :zone
  validates_uniqueness_of :exported_as, :if => :exported_as

  validates_format_of :name, :with => /^[\w -]*$/n, :message => "must only contain: numbers, letters, spaces, '_' and '-'"

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  def cloud_accounts
    accounts = []
    instances.each do |instance|
      if instance.cloud_account and !accounts.include?(instance.cloud_account)
        accounts << instance.cloud_account
      end
    end
  end

  def images
    Image.find(:all, :conditions => {:provider_id => nil})
  end

  def hardware_profiles
    HardwareProfile.find(:all, :conditions => {:provider_id => nil})
  end

  def realms
    Realm.find(:all, :conditions => { :provider_id => nil })
  end

end
