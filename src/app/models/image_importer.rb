class ImageImporter
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :pool_family_id, :provider_account_id, :image_id, :name,
                :provider_image

  validates_presence_of :pool_family_id, :provider_account_id, :image_id, :name
  validate :valid_image_id?

  def initialize(attributes = {})
    if attributes
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end
  end

  def import(user)
    true
  end

  def persisted?
    false
  end

  private

  def valid_image_id?
    account = ProviderAccount.find(provider_account_id)
    conn = provider_account.connect

    dc_image = conn.image(image_id) rescue nil
    if dc_image.blank?
      errors.add(:base, t('image_importer.not_on_provider'))
      return false
    end

    true
  end
end
