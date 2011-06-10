require 'warehouse_client'
class BucketObjectNotFound < Exception;end
class BucketNotFound < Exception;end

class WarehouseModel
  WAREHOUSE_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/image_warehouse.yml")

  def ==(other_obj)
    # If the objects have different instance variables defined, they're definitely not ==
    return false unless instance_variables.sort == other_obj.instance_variables.sort
    # Otherwise, ensure that they're all the same
    instance_variables.each do |iv|
      return false unless other_obj.instance_variable_get(iv) == instance_variable_get(iv)
    end
    # They have the same instance variables and values, so they're equal
    true
  end

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

    def bucket_objects
      self.set_warehouse_and_bucket if self.bucket.nil?

      begin
        self.bucket.objects
      rescue RestClient::ResourceNotFound
        []
      end
    end

    def first
    obj = bucket_objects.first
      obj ? self.new(obj.attrs(obj.attr_list)) : nil
    end

    def last
      obj = bucket_objects.last
      obj ? self.new(obj.attrs(obj.attr_list)) : nil
    end

    def all
      bucket_objects.map do |wh_object|
          self.new(wh_object.attrs(wh_object.attr_list))
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