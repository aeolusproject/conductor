class AddPoolFamilyQuota < ActiveRecord::Migration
  def self.up
    add_column :pool_families, :quota_id, :integer
    PoolFamily.all.each do |pf|
      unless pf.quota
        pf.quota = Quota.new
        pf.save!
      end
    end
  end

  def self.down
    remove_column :pool_families, :quota_id
  end
end
