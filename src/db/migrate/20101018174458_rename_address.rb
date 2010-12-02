class RenameAddress < ActiveRecord::Migration
  def self.up
    rename_column :instances, :public_address, :public_addresses
    rename_column :instances, :private_address, :private_addresses
    remove_column :instances, :public_ip_addresses
  end

  def self.down
  end
end
