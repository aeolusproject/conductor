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
  belongs_to :cloud_account
  has_many :instances,  :dependent => :destroy

  # what form does the pool quota take?

  validates_presence_of :cloud_account_id

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :cloud_account_id

  def populate_realms_and_images
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
        #FIXME: we need to handle keeping in sync forupdates as well as
        # account permissions
        unless Image.find_by_external_key_and_provider_id(image.id,
                                                     cloud_account.provider.id)
          ar_image = Image.new(:external_key => image.id,
                               :name => image.name ? image.name :
                                        (image.description ? image.description :
                                                             image.id),
                               :architecture => image.architecture,
                               :provider_id => cloud_account.provider.id)
          ar_image.save!
        end
      end
    end
  end


end
