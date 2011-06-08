require 'warehouse_client'
class BucketObjectNotFound < Exception;end
class BucketNotFound < Exception;end

class WarehouseModel
  WAREHOUSE_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/image_warehouse.yml")

  class << self
    attr_accessor :warehouse, :bucket, :bucket_name

    def set_warehouse_and_bucket
      begin
        self.warehouse = Warehouse::Client.new(WAREHOUSE_CONFIG['baseurl'])
        self.bucket = self.warehouse.bucket(@bucket_name)
      rescue
        raise BucketNotFound
      end
    end

    def all
      self.set_warehouse_and_bucket if self.bucket.nil?

      begin
        self.bucket.objects.map do |wh_object|
          self.new(wh_object.attrs(wh_object.attr_list))
        end
      rescue RestClient::ResourceNotFound
        []
      end
    end

    def find(uuid)
      self.set_warehouse_and_bucket if self.bucket.nil?
      begin
        if self.bucket.include?(uuid)
          self.new(self.bucket.object(uuid).attrs(self.bucket.object(uuid).attr_list))
        else
          nil
        end
      rescue RestClient::ResourceNotFound
        nil
      end
    end

    def where(query_string)
      self.set_warehouse_and_bucket if self.bucket.nil?
      self.warehouse.query(@bucket_name, query_string)
    end
  end
end