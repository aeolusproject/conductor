class RenameCondorcloud < ActiveRecord::Migration
  def self.up
    # Not sure why this is necessary, but it is:
    ProviderType.reset_column_information
    condorcloud_type =  ProviderType.find_by_deltacloud_driver('condorcloud')
    if condorcloud_type
      condorcloud_type.deltacloud_driver = "condor"
      condorcloud_type.save!
    end
  end

  def self.down
    condor_type =  ProviderType.find_by_deltacloud_driver('condor')
    if condor_type
      condor_type.deltacloud_driver = "condorcloud"
      condor_type.save!
    end
  end
end
