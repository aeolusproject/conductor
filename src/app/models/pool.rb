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
# Schema version: 20110603204130
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
#  enabled        :boolean
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Pool < ActiveRecord::Base
  include PermissionedObject
  include ActionView::Helpers::NumberHelper
  has_many :instances,  :dependent => :destroy
  belongs_to :quota, :autosave => true, :dependent => :destroy
  belongs_to :pool_family
  has_many :deployments
  # NOTE: Commented out because images table doesn't have pool_id foreign key?!
  #has_many :images,  :dependent => :destroy
  has_many :catalogs, :dependent => :destroy

  validates_presence_of :name
  validates_presence_of :quota
  validates_presence_of :pool_family
  validates_inclusion_of :enabled, :in => [true, false]
  validates_uniqueness_of :name
  validates_uniqueness_of :exported_as, :if => :exported_as
  validates_length_of :name, :maximum => 255

  validates_format_of :name, :with => /^[\w -]*$/n, :message => "must only contain: numbers, letters, spaces, '_' and '-'"

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  has_many :deployments, :dependent => :destroy

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

  def enabled?
    self.enabled and pool_family and pool_family.enabled?
  end

  # TODO: Implement Alerts and Updates
  def statistics
    # TODO - Need to set up cache invalidation before this is safe
    #Rails.cache.fetch("pool-#{id}-statistics") do
      {
        :cloud_providers => instances.collect{|i| i.provider_account}.uniq.count,
        :deployments => deployments.count,
        :total_instances => (instances.deployed.count +
                             instances.pending.count + instances.failed.count),
        :instances_deployed => instances.deployed.count,
        :instances_pending => instances.pending.count,
        :instances_failed => instances.failed.count,
        :used_quota => quota.running_instances,
        :quota_percent => number_to_percentage(quota.percentage_used,
                                               :precision => 0),
        :available_quota => quota.maximum_running_instances
      }
    #end
  end

  def self.list(order_field, order_dir)
    Pool.all(:include => [ :quota, :pool_family ],
             :order => (order_field || 'name') +' '+ (order_dir || 'asc'))
  end

  def as_json(options={})
    result = super(options).merge({
      :statistics => statistics,
      :deployments_count => deployments.count,
      :pool_family => {
        :name => pool_family.name,
        :id => pool_family.id,
      },

    })

    if options[:with_deployments]
      result[:deployments] = deployments.map {|d| d.as_json}
    end

    result
  end

  def provider_image_map
    catalog_entries = catalogs.collect{|c| c.catalog_entries}.flatten
    all_images = catalog_entries.collect{|ce| ce.fetch_images}.flatten.uniq
    provider_images = Image.provider_images_for_image_list(all_images)

    return_obj = {}
    catalogs.each do |catalog|
      return_obj[catalog] = {}
      catalog.catalog_entries.each do |catalog_entry|
        return_obj[catalog][catalog_entry] = {}
        images = catalog_entry.fetch_images
        images.each do |image|
          return_obj[catalog][catalog_entry][image] = provider_images[image.uuid]
        end
      end
    end
    return_obj
  end

end
