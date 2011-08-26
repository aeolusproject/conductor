class RenameRhevmTarget < ActiveRecord::Migration

  def self.up
    type = ProviderType.find_by_codename("rhevm")
    if type
      type.codename = "rhev-m"
      type.save
    end
  end

  def self.down
    type = ProviderType.find_by_codename("rhev-m")
    if type
      type.codename = "rhevm"
      type.save
    end
  end

end
