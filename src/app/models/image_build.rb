class ImageBuild < WarehouseModel
  @bucket_name = 'builds'

  def initialize(attrs)
    attrs.each do |k,v|
      if k.to_sym == :image
        sym = :attr_writer
      else
        sym = :attr_accessor
      end
      self.class.send(sym, k.to_sym) unless respond_to?(:"#{k}=")
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

  def image
    Image.find(@image) if @image
  end

  def target_images
    TargetImage.all.select {|ti| ti.build and (ti.build.uuid == self.uuid)}
  end

  def provider_images
    targets = target_images
    ProviderImage.all.select do |pi|
      targets.include?(pi.target_image)
    end
  end
end
