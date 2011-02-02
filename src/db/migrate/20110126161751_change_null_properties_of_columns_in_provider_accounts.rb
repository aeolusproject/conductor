class ChangeNullPropertiesOfColumnsInProviderAccounts < ActiveRecord::Migration
  def self.up
    change_column :provider_accounts, :account_number, :string, :null => true
    change_column :provider_accounts, :x509_cert_priv, :text, :null => true
    change_column :provider_accounts, :x509_cert_pub, :text, :null => true
  end

  def self.down
    change_column :provider_accounts, :account_number, :string, :null => false
    change_column :provider_accounts, :x509_cert_priv, :text, :null => false
    change_column :provider_accounts, :x509_cert_pub, :text, :null => false
  end
end
