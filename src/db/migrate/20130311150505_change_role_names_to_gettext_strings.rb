class ChangeRoleNamesToGettextStrings < ActiveRecord::Migration
  NEW_NAMES = {
    "instance.user"            => "Role|Instance User",
    "instance.owner"           => "Role|Instance Owner",
    "deployment.user"          => "Role|Deployment User",
    "deployment.owner"         => "Role|Deployment Owner",
    "tim.base_image.user"      => "Role|Image User",
    "tim.base_image.owner"     => "Role|Image Owner",
    "tim.template.user"        => "Role|Template User",
    "tim.template.owner"       => "Role|Template Owner",
    "pool_family.user"         => "Role|Environment User",
    "pool_family.image.admin"  => "Role|Environment Image Administrator",
    "pool_family.admin"        => "Role|Environment Administrator",
    "pool.user"                => "Role|Pool User",
    "pool.deployable.admin"    => "Role|Pool Deployable Admin",
    "pool.admin"               => "Role|Pool Administrator",
    "provider_type.owner"      => "Role|Provider Type Owner",
    "provider.admin"           => "Role|Provider Administrator",
    "provider.user"            => "Role|Provider User",
    "provider_account.user"    => "Role|Provider Account User",
    "provider_account.owner"   => "Role|Provider Account Owner",
    "catalog.user"             => "Role|Catalog User",
    "catalog.admin"            => "Role|Catalog Administrator",
    "deployable.user"          => "Role|Deployable User",
    "deployable.owner"         => "Role|Deployable Owner",
    "base.provider.user"       => "Role|Global Provider User",
    "base.provider.admin"      => "Role|Global Provider Administrator",
    "base.hwp.admin"           => "Role|Global HWP Administrator",
    "base.realm.admin"         => "Role|Global Realm Administrator",
    "base.pool.admin"          => "Role|Global Pool Administrator",
    "base.deployable.admin"    => "Role|Global Deployable Administrator",
    "base.hwp.user"            => "Role|Global HWP User",
    "base.pool.user"           => "Role|Global Pool User",
    "base.image.admin"         => "Role|Global Image Administrator",
    "base.admin"               => "Role|Global Administrator"
  }
  OLD_NAMES = NEW_NAMES.invert

  def self.up
    say_with_time "Updating role names for gettext..." do
      Role.find(:all).each do |role|
        new_name = NEW_NAMES[role.name]
        role.update_column :name, new_name if new_name
      end
    end
  end

  def self.down
    say_with_time "Reverting role names for gettext..." do
      Role.find(:all).each do |role|
        old_name = OLD_NAMES[role.name]
        role.update_column :name, old_name if old_name
      end
    end
  end

end
