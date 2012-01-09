class ChangeColumnValueInstanceParameters < ActiveRecord::Migration
  def self.up
    change_column :instance_parameters, :value, :text
  end

  def self.down
    change_column :instance_parameters, :value, :string
  end
end
