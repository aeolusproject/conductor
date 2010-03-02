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

class PortalPool < ActiveRecord::Base
  include PermissionedObject
  has_many :pool_accounts, :dependent => :destroy
  has_many :cloud_accounts, :through => :pool_accounts
  has_many :instances,  :dependent => :destroy
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"

  has_many :images,  :dependent => :destroy
  has_many :hardware_profiles,  :dependent => :destroy



  validates_presence_of :owner_id
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :owner_id
  validates_uniqueness_of :exported_as, :if => :exported_as

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  def realms
    realm_list = []
    cloud_accounts.each do |cloud_account|
      prefix = cloud_account.provider.name +
               Realm::AGGREGATOR_REALM_PROVIDER_DELIMITER +
               cloud_account.username
      realm_list << prefix
      cloud_account.provider.realms.each do |realm|
        realm_list << prefix + Realm::AGGREGATOR_REALM_ACCOUNT_DELIMITER +
                      realm.name
      end
    end
    realm_list
  end

  # FIXME: for already-mapped accounts, update rather than add new
  def populate_realms_and_images(accounts=cloud_accounts)
    accounts.each do |cloud_account|
      client = cloud_account.connect
      realms = client.realms
      if client.driver_name == "ec2"
        images = client.images(:owner_id=>:self)
      else
        images = client.images
      end
      # FIXME: this should probably be in the same transaction as portal_pool.save
      self.transaction do
        realms.each do |realm|
          #ignore if it exists
          #FIXME: we need to handle keeping in sync forupdates as well as
          # account permissions
          unless Realm.find_by_external_key_and_provider_id(realm.id,
                                                            cloud_account.provider.id)
            ar_realm = Realm.new(:external_key => realm.id,
                                 :name => realm.name ? realm.name : realm.id,
                                 :provider_id => cloud_account.provider.id)
            ar_realm.save!
          end
        end
        images.each do |image|
          #ignore if it exists
          #FIXME: we need to handle keeping in sync for updates as well as
          # account permissions
          ar_image = Image.find_by_external_key_and_provider_id(image.id,
                                                     cloud_account.provider.id)
          unless ar_image
            ar_image = Image.new(:external_key => image.id,
                                 :name => image.name ? image.name :
                                          (image.description ? image.description :
                                                               image.id),
                                 :architecture => image.architecture,
                                 :provider_id => cloud_account.provider.id)
            ar_image.save!
          end
          # FIXME: what do we ue for external_key values for front end images?
          # FIXME: this will break if multiple imported accounts (from different
          #        providers) use the same external key
          front_end_image = Image.new(:external_key => ar_image.external_key,
                                  :name => ar_image.name,
                                  :architecture => ar_image.architecture,
                                  :portal_pool_id => id)
          front_end_image.save!
        end
        cloud_account.provider.hardware_profiles.each do |hardware_profile|
          front_hardware_profile = HardwareProfile.new(:external_key =>
                                                       hardware_profile.external_key,
                               :name => hardware_profile.name,
                               :memory => hardware_profile.memory,
                               :storage => hardware_profile.storage,
                               :architecture => hardware_profile.architecture,
                               :portal_pool_id => id)
          front_hardware_profile.save!
        end
      end
    end
  end


end
