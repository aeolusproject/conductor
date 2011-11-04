class AlterMetadataObjectValueLimit < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE metadata_objects ALTER COLUMN value TYPE varchar(510)"
  end

  def self.down
  end
end
