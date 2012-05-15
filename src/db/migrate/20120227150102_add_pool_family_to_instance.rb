class AddPoolFamilyToInstance < ActiveRecord::Migration
  def self.up
    add_column :instances, :pool_family_id, :integer
    add_column :deployments, :pool_family_id, :integer
    add_column :catalogs, :pool_family_id, :integer
    add_column :deployables, :pool_family_id, :integer

    Deployment.unscoped.each do |deployment|
      deployment.pool_family_id = deployment.pool.pool_family_id
      deployment.save!
    end
    Instance.unscoped.each do |instance|
      instance.pool_family_id = instance.pool.pool_family_id
      instance.save!
    end
    Catalog.all.each do |catalog|
      catalog.pool_family_id = catalog.pool.pool_family_id
      catalog.save!
    end
    Deployable.all.each do |deployable|
      deployable.pool_family_id = deployable.catalogs.first.pool_family_id unless deployable.catalogs.empty?
      deployable.save!
    end
  end

  def self.down
    remove_column :instances, :pool_family_id
    remove_column :deployments, :pool_family_id
    remove_column :catalogs, :pool_family_id
    remove_column :deployables, :pool_family_id
  end
end
