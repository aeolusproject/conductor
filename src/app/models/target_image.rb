class TargetImage < WarehouseModel
  @bucket_name = 'target_images'

  def initialize(attrs)
    attrs.each do |k,v|
      if k.to_sym == :build
        sym = :attr_writer
      else
        sym = :attr_accessor
      end
      self.class.send(sym, k.to_sym) unless respond_to?(:"#{k}=")
      send(:"#{k}=", v)
    end
  end

  def build
    ImageBuild.find(@build) if @build
  end

  def provider_images
    ProviderImage.all.select{|pi| pi.target_image and (pi.target_image.uuid == self.uuid)}
  end
end
