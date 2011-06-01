class AddDeployableXmlToDeployments < ActiveRecord::Migration
  def self.up
    add_column :deployments, :deployable_xml, :text
  end

  def self.down
    drop_column :deployments, :deployable_xml
  end
end
