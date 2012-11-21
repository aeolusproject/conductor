Tim::ProviderImage.class_eval do
  def self.find_by_images(images)
    ProviderImage.joins(:target_image => :image_version).
      where(:tim_image_versions => {:base_image_id => [images.map(&:id)]})
  end

  def base_image
    target_image.base_image
  end
end
