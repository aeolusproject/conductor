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
end
