class AddStatusToProviderImage < ActiveRecord::Migration
  def self.up
    add_column :legacy_provider_images, :status, :string
    LegacyProviderImage.all.each do |image|
      if image.uploaded
        image.status = 'completed'
      else
        image.status = "queued"
      end
      image.save!
    end
    remove_column :legacy_provider_images, :uploaded
    remove_column :legacy_provider_images, :registered
  end

  def self.down
    add_column :legacy_provider_images, :uploaded, :boolean
    add_column :legacy_provider_images, :registered, :boolean
    LegacyProviderImage.all.each do |image|
      if image.status == 'completed'
        image.uploaded = true
        image.registered = true
      else
        image.uploaded = false
        image.registered = false
      end
      image.save!
    end
    remove_column :legacy_provider_images, :status
  end
end
