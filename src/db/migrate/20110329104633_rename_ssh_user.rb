class RenameSshUser < ActiveRecord::Migration
  def self.up
    pt = ProviderType.first(:conditions => {:codename => 'ec2'})
    pt.ssh_user = 'root'
    pt.home_dir = '/root'
    pt.save!
  end

  def self.down
    pt = ProviderType.first(:conditions => {:codename => 'ec2'})
    pt.ssh_user = 'ec2-user'
    pt.home_dir = '/home/ec2-user'
    pt.save!
  end
end
