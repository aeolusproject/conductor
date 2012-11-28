Tim::ProviderImage.class_eval do
  belongs_to :provider_account

  validates_presence_of :provider_account
  validate :valid_external_image_id?, :if => :imported?

  before_create :set_credentials

  STATUS_COMPLETE = 'COMPLETE'

  def self.find_by_images(images)
    ProviderImage.joins(:target_image => :image_version).
      where(:tim_image_versions => {:base_image_id => [images.map(&:id)]})
  end

  def self.find_by_provider_account_and_image_version(account, version)
    joins(:target_image => :image_version).
      where(:provider_account_id => account.id,
            'tim_image_versions.id' => version.id,
            :status => STATUS_COMPLETE)
  end

  def self.find_by_provider_account_and_image(account, image)
    joins(:target_image => :image_version).
      where(:tim_image_versions => {:base_image_id => image.id},
            :provider_account_id => account.id,
            :status => STATUS_COMPLETE)
  end

  def base_image
    target_image.base_image
  end

  def valid_external_image_id?
    account = ProviderAccount.find(provider_account_id)
    conn = provider_account.connect

    dc_image = conn.image(image_id) rescue nil
    if dc_image.blank?
      errors.add(:base, t('tim.base_images.import.not_on_provider'))
      return false
    end

    true
  end

  private

  def set_credentials
    @credentials = provider_account.to_xml(:with_credentials => true)
  end
end
