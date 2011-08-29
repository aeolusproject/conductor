class RemoveCondorJobIdFromInstances < ActiveRecord::Migration
  def self.up
    remove_column :instances, :condor_job_id
  end

  def self.down
    add_column :instances, :condor_job_id, :string
  end
end
