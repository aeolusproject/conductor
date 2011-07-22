#
# Copyright (C) 2010 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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

require 'warehouse_client'

class WarehouseObjectNotFoundError < Exception;end

module ImageWarehouseObject

  WAREHOUSE_CONFIG = YAML.load_file("#{::Rails.root.to_s}/config/image_warehouse.yml")

  def xml
    @xml ||= ImageDescriptorXML.new(self[:xml].to_s)
  end

  # this should be overriden in a model if model wants to save additional attrs
  def warehouse_attrs
    {:uuid => self.uuid, :object_type => self.class.class_name}
  end

  # this should be overriden in a model if model wants to save a body
  def warehouse_body
    nil
  end

  # TODO: it would be nice not call upload, when save was invoked by warehouse
  # sync script
  def upload
    # TODO: for now there is no way how it check if bucket exists in warehouse
    # so we try to create bucket everytime, if bucket exists, warehouse returns
    # 500 Internal server error
    raise "uuid is not set" unless self.uuid
    warehouse.create_bucket(warehouse_bucket) rescue true
    # TODO: we delete existing object if it exists
    warehouse.bucket(warehouse_bucket).object(self.uuid).delete! rescue true
    warehouse.bucket(warehouse_bucket).create_object(self.uuid, warehouse_body, warehouse_attrs)
  end

  def delete_in_warehouse
    begin
      warehouse.bucket(warehouse_bucket).object(self.uuid).delete!
    rescue
      logger.error "failed to delete #{self.uuid} in warehouse: #{$!}"
    end
  end

  def warehouse
    @warehouse ||= Warehouse::Client.new(WAREHOUSE_CONFIG['baseurl'])
  end

  def warehouse_url
    "#{WAREHOUSE_CONFIG['baseurl']}/#{warehouse_bucket}/#{self.uuid}"
  end

  def safe_warehouse_sync
    warehouse_sync
    log_changes
  rescue RestClient::ResourceNotFound, WarehouseObjectNotFoundError
    logger.error "Failed to fetch #{self.class.class_name} with uuid #{self.uuid} - not found in warehouse"
  rescue => e
    logger.error "Failed to sync #{self.class.class_name} with uuid #{self.uuid}: #{e.message}"
    logger.error e.backtrace.join("\n   ")
  end

  def log_changes
    if self.new_record?
      logger.info "#{self.class.class_name} #{self.uuid} is not in DB yet"
    elsif self.changed?
      logger.info "#{self.class.class_name} #{self.uuid} has been changed:"
      self.changed.each do |attr|
        logger.info "old #{attr}: #{self.send(attr + '_was')}"
        logger.info "new #{attr}: #{self[attr]}"
      end
    else
      logger.info "#{self.class.class_name} #{self.uuid} is without changes"
    end
  end

  def generate_uuid
    # TODO: generate real uuid here, e.g. with some ruby uuid generator
    self.uuid ||= UUIDTools::UUID.timestamp_create.to_s
  end
end
