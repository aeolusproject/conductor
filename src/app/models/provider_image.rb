class ProviderImage < WarehouseModel
  @bucket_name = 'provider_images'

  def initialize(attrs)
    attrs.each do |k,v|
      self.class.send(:attr_accessor, k.to_sym) unless respond_to?(:"#{k}=")
      send(:"#{k}=", v)
    end
  end
end