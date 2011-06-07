class ImageBuild < WarehouseModel
  @bucket_name = 'builds'

  def initialize(attrs)
    attrs.each do |k,v|
      self.class.send(:attr_accessor, k.to_sym) unless respond_to?(:"#{k}=")
      send(:"#{k}=", v)
    end
  end

  def self.find_all_by_image_uuid(uuid)
    self.set_warehouse_and_bucket if self.bucket.nil?
    self.bucket.objects.map do |wh_object|
      if wh_object.attr('image')[1] == uuid
        ImageBuild.new(wh_object.attrs(wh_object.attr_list))
      end
    end.compact
  end

  def target_images
    TargetImage.all.select {|ti| ti.build == self.uuid}
  end

  def provider_images
    target_uuids = target_images.collect {|ti| ti.uuid }
    ProviderImage.all.select do |pi|
      target_uuids.include?(pi.target_image)
    end
  end
end
