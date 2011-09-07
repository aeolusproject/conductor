class Image < WarehouseModel
  @bucket_name = 'images'

  def initialize(attrs)
    attrs.each do |k,v|
      if k.to_sym == :latest_build
        sym = :attr_writer
      else
        sym = :attr_accessor
      end
      self.class.send(sym, k.to_sym) unless respond_to?(:"#{k}=")
      send(:"#{k}=", v)
    end
  end

  def latest_build
    ImageBuild.find(@latest_build) if @latest_build
  end

  def image_builds
    ImageBuild.find_all_by_image_uuid(self.uuid)
  end

  # This is extraordinarily inefficient, but we allow it assuming that the calls we're
  # making will be optimized soon enough.
  # Returns a hash of {image => [ProviderImages]}, which is really weird but exactly what we'll need
  def self.provider_images_for_images(images)
    return_obj = {}
    images.each do |image|
      return_obj[image] = []
      uuid = image.uuid
      Aeolus::Image::ImageBuild.find_all_by_image_uuid(uuid).each do |build|
        build.target_images.each do |target_image|
          target_image.provider_images.each do |provider_image|
            return_obj[image] << provider_image
          end
        end
      end
    end
    return_obj
  end

end
