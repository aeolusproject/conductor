class AddStatusToProviderImage < ActiveRecord::Migration
  def self.up
    add_column :provider_images, :status, :string
    ProviderImage.all.each do |image|
      if image.uploaded
        image.status = "complete"
      else
        image.status = "queued"
      end
      image.save!
    end
    remove_column :provider_images, :uploaded
    remove_column :provider_images, :registered
  end

  def self.down
    add_column :provider_images, :uploaded, :boolean
    add_column :provider_images, :registered, :boolean
    ProviderImage.all.each do |image|
      if image.status == "complete"
        image.uploaded = true
        image.registered = true
      else
        image.uploaded = false
        image.registered = false
      end
      image.save!
    end
    remove_column :provider_images, :status
  end
end
