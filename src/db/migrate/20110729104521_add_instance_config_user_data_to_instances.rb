class AddInstanceConfigUserDataToInstances < ActiveRecord::Migration
  def self.up
    add_column :instances, :instance_config_xml, :text, :null => true
    add_column :instances, :user_data, :text, :null => true
  end

  def self.down
    remove_column :instances, :instance_config_xml
    remove_column :instances, :user_data
  end
end
