Tim::TargetImage.class_eval do
  belongs_to :provider_type

  validates_presence_of :provider_type

  before_validation :set_provider_type
  before_create :set_target

  def set_provider_type
    # if provider_type is not set but provider_image is set, get provider
    # type from provider image's provider account
    if provider_type.nil? and provider_images.present? and
      provider_images.first.provider_account

      self.provider_type = provider_images.first.provider_account.
        provider.provider_type
    end
  end

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
    @target = provider_type.name
  end
end
