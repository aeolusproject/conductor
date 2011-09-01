class AddViewHardwareProfilePrivilegesToAdmins < ActiveRecord::Migration
  def self.up
    return if Role.all.empty?

    Role.transaction do
      ["HWP Administrator", "Administrator"].each do |role_name|
        role = Role.find_or_initialize_by_name(role_name)

        priv_type = HardwareProfile
        priv_action = 'view'
        Privilege.create!(:role => role, :target_type => 'HardwareProfile',
                          :action => 'view')
      end
    end
  end

  def self.down
  end
end
