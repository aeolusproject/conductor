class RenameRhevmTarget < ActiveRecord::Migration

  def self.up
    type = ProviderType.find_by_codename("rhevm")
    type.codename = "rhev-m"
    type.save
  end

  def self.down
    type = ProviderType.find_by_codename("rhev-m")
    type.codename = "rhevm"
    type.save
  end

end
