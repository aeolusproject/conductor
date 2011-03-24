class CreateCredentials < ActiveRecord::Migration
  def self.up
    create_table :credentials do |t|
      t.integer :provider_account_id
      t.text :value
      t.integer :credential_definition_id, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :credentials
  end
end
