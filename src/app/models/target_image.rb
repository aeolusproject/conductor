class TargetImage < WarehouseModel
  @bucket_name = 'target_images'

  def initialize(attrs)
    attrs.each do |k,v|
      self.class.send(:attr_accessor, k.to_sym) unless respond_to?(:"#{k}=")
      send(:"#{k}=", v)
    end
  end

  def provider_images
    ProviderImage.all.collect{|pi| pi.target_image == self.uuid}
  end
end