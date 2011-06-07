class ProviderImage < WarehouseModel
  @bucket_name = 'provider_images'

  def initialize(attrs)
    attrs.each do |k,v|
      self.class.send(:attr_accessor, k.to_sym) unless respond_to?(:"#{k}=")
      send(:"#{k}=", v)
    end
  end

  def provider
    Provider.find_by_name(@provider)
  end

  def self.find_all_by_provider_and_build(provider, build)
    provider_name = provider.name
    build_uuid = build.uuid
    self.set_warehouse_and_bucket if self.bucket.nil?
    self.bucket.objects.map do |wh_object|
      if wh_object.attr('provider')[1] == provider_name
        # FIX ME: We need to add build metadata tag so we don't need
        # this extra query
        target_uuid = wh_object.attr('target_image')[1]
        if TargetImage.find(target_uuid).build == build_uuid
          ProviderImage.new(wh_object.attrs(wh_object.attr_list))
        end
      end
    end.compact
  end
end
