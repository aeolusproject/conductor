class Image < WarehouseModel
  @bucket_name = 'images'

  def initialize(attrs)
    attrs.each do |k,v|
      self.class.send(:attr_accessor, k.to_sym) unless respond_to?(:"#{k}=")
      send(:"#{k}=", v)
    end
  end

  def image_builds
    ImageBuild.find_all_by_image_uuid(self.uuid)
  end
end