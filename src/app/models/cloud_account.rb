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

class CloudAccount < ActiveRecord::Base
  include PermissionedObject
  belongs_to :provider
  belongs_to :quota
  has_many :instances

  # what form does the account quota take?

  validates_presence_of :provider_id

  validates_presence_of :username
  validates_uniqueness_of :username, :scope => :provider_id
  validates_presence_of :password

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"


  before_destroy {|entry| entry.destroyable? }

  def destroyable?
    self.instances.empty?
  end

  def connect
    begin
      return DeltaCloud.new(username, password, provider.url)
    rescue Exception => e
      logger.error("Error connecting to framework: #{e.message}")
      logger.error("Backtrace: #{e.backtrace.join("\n")}")
      return nil
    end
  end

  def self.find_or_create(account)
    a = CloudAccount.find_by_username_and_provider_id(account["username"], account["provider_id"])
    return a.nil? ? CloudAccount.new(account) : a
  end

  def account_prefix_for_realm
    provider.name + Realm::AGGREGATOR_REALM_PROVIDER_DELIMITER + username
  end

  def pools
    pools = []
    instances.each do |instance|
      pools << instance.pool
    end
  end

  def name
    label.nil? || label == "" ? username : label
  end

  # FIXME: for already-mapped accounts, update rather than add new
  def populate_realms_and_images
    client = connect
    realms = client.realms
    # FIXME: the "self" filtering has to go as soon as we have a decent image selection UI
    if client.driver_name == "ec2"
      images = client.images(:owner_id=>:self)
    else
      images = client.images
    end
    # FIXME: this should probably be in the same transaction as cloud_account.save
    self.transaction do
      realms.each do |realm|
        #ignore if it exists
        #FIXME: we need to handle keeping in sync forupdates as well as
        # account permissions
        unless Realm.find_by_external_key_and_provider_id(realm.id,
                                                          provider.id)
          ar_realm = Realm.new(:external_key => realm.id,
                               :name => realm.name ? realm.name : realm.id,
                               :provider_id => provider.id)
          ar_realm.save!
        end
      end
      images.each do |image|
        #ignore if it exists
        #FIXME: we need to handle keeping in sync for updates as well as
        # account permissions
        ar_image = Image.find_by_external_key_and_provider_id(image.id,
                                                              provider.id)
        unless ar_image
          ar_image = Image.new(:external_key => image.id,
                               :name => image.name ? image.name :
                               (image.description ? image.description :
                                image.id),
                               :architecture => image.architecture,
                               :provider_id => provider.id)
          ar_image.save!
          front_end_image = Image.new(:external_key =>
                                      provider.name +
                                      Realm::AGGREGATOR_REALM_ACCOUNT_DELIMITER +
                                      ar_image.external_key,
                                      :name => provider.name +
                                      Realm::AGGREGATOR_REALM_ACCOUNT_DELIMITER +
                                      ar_image.name,
                                      :architecture => ar_image.architecture)
          front_end_image.provider_images << ar_image
          front_end_image.save!
        end
      end
    end
  end

  protected
  def validate
    errors.add_to_base("Login Credentials are Invalid for this Provider") unless valid_credentials?
  end

  private
  def valid_credentials?
    begin
      deltacloud = DeltaCloud.new(username, password, provider.url)
      #TODO This should be replaced by a DeltaCloud.test_credentials type method once/if it is implemented in the API
      deltacloud.instances
    rescue Exception => e
      return false
    end
    return true
  end

end
