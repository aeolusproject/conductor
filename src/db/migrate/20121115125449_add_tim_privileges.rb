class AddTimPrivileges < ActiveRecord::Migration
  VIEW = "view"
  USE  = "use"
  MOD  = "modify"
  CRE  = "create"
  VPRM = "view_perms"
  GPRM = "set_perms"

  ROLES = %w(pool_family.image.admin pool_family.admin base.image.admin
             base.admin)
  def self.up
    # This is meant to be an incremental update for existing installs, so if this is a fresh install,
    # bail out -- db:seeds will take care of this for us:
    return if Role.count == 0

    ROLES.each do |role_name|
      role = Role.find_by_name(role_name)
      next unless role
      [VIEW, USE, MOD, CRE, VPRM, GPRM].each do |action|
        Privilege.create!(:role => role, :target_type => Tim::BaseImage.name,
                          :action => action)
        Privilege.create!(:role => role, :target_type => Tim::Template.name,
                          :action => action)
      end
    end
  end

  def self.down
    ROLES.each do |role_name|
      role = Role.find_by_name(role_name)
      next unless role
      role.privileges.where(:target_type => Tim::Template.name).each do |priv|
        priv.destroy
      end
      role.privileges.where(:target_type => Tim::BaseImage.name).each do |priv|
        priv.destroy
      end
    end
  end
end
