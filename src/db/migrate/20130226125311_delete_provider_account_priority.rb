class DeleteProviderAccountPriority < ActiveRecord::Migration
  def up
    remove_column :provider_accounts, :priority

  end

  def down
    add_column :provider_accounts, :priority, :integer
  end
end
