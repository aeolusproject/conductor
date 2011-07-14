class CreateConfigServer < ActiveRecord::Migration
  def self.up
    create_table :config_servers do |t|
      t.string :host, :null => false
      t.string :port, :null => false
      t.string :username, :null => true
      t.string :password, :null => true
      t.string :certificate, :null => true, :limit => 2048
      t.integer :provider_account_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :config_servers
  end
end
