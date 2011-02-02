class RenameCloudAccountToProviderAccount < ActiveRecord::Migration
  def self.up
    rename_table (:cloud_accounts,:provider_accounts)
    remove_column (:providers, :cloud_type)
    add_column (:providers, :provider_type, :integer)
  end

  def self.down
    remove_column (:providers, :provider_type)
    add_column (:providers, :cloud_type, :string, :null => false)
    rename_table (:provider_accounts, :cloud_accounts)
  end
end
