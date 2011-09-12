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

  # The iwhd API really isn't built for what we're trying to do.
  # Here's a nutty workaround to not issues thousands of queries.
  # images should be an array of Aeolus::Image::Image objects
  # Please don't shoot me for this!
  def self.provider_images_for_image_list(images)
    # Fetch all of these, but only once
    provider_images = Aeolus::Image::ProviderImage.all
    target_images = Aeolus::Image::TargetImage.all
    builds = Aeolus::Image::ImageBuild.all
    return_objs = {}
    images.each do |image|
      _builds = builds.select{|b| b.instance_variable_get('@image') == image.uuid}
      _builds.each do |build|
        _target_images = target_images.select{|ti| ti.instance_variable_get('@build') == build.uuid}
        _target_images.each do |target_image|
          _provider_images = provider_images.select{|pi| pi.instance_variable_get('@target_image') == target_image.uuid}
          return_objs[image.uuid] = _provider_images
        end
      end
    end
    return_objs
  end

end
