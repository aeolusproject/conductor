class RenameRhevmAndVmwareTargets < ActiveRecord::Migration

  def self.up
    rename_type("rhev-m", "rhevm")
    rename_type("vmware", "vsphere")
  end

  def self.down
    rename_type("rhevm", "rhev-m")
    rename_type("vsphere", "vmware")
  end

  def self.rename_type(old, new)
    type = ProviderType.find_by_codename(old)
    if type
      type.codename = new
      type.save
    end
  end

end
