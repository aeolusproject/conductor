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
