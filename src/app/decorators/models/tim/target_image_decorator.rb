Tim::TargetImage.class_eval do
  belongs_to :provider_type

  validates_presence_of :provider_type

  before_create :set_target

  def self.find_by_images(images)
    TargetImage.joins(:image_version).
      where(:tim_image_versions => {:base_image_id => [images.map(&:id)]})
  end

  def base_image
    image_version.base_image
  end

  private

  def set_target
    # TODO: codenames have changed in new imagefactory
    @target = provider_type.codename
  end
end
