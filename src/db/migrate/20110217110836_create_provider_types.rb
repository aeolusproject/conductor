class CreateProviderTypes < ActiveRecord::Migration
  def self.up
    create_table :provider_types do |t|
      t.string :name, :null => false
      t.string :codename, :null => false
      t.string :ssh_user
      t.string :home_dir
      t.boolean :build_supported, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :provider_types
  end
end
