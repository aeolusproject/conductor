class ChangeCloudaccountValueToProvideraccountInPrivilegesAndRoles < ActiveRecord::Migration
  def self.up
    execute "UPDATE privileges SET target_type='ProviderAccount' WHERE target_type='CloudAccount';"
    execute "UPDATE roles SET scope='ProviderAccount' WHERE scope='CloudAccount';"
  end

  def self.down
    execute "UPDATE privileges SET target_type='CloudAccount' WHERE target_type='ProviderAccount';"
    execute "UPDATE roles SET scope='CloudAccount' WHERE scope='ProviderAccount';"
  end
end
