class MigrateDataToAlberich < ActiveRecord::Migration
  class BasePermissionObject < ActiveRecord::Base; end
  class Alberich::BasePermissionObject < ActiveRecord::Base; end
  class PermissionSession < ActiveRecord::Base; end
  class Alberich::PermissionSession < ActiveRecord::Base; end

  class Role < ActiveRecord::Base; end
  class Alberich::Role < ActiveRecord::Base; end

  class Privilege < ActiveRecord::Base; end
  class Alberich::Privilege < ActiveRecord::Base; end

  class Entity < ActiveRecord::Base; end
  class Alberich::Entity < ActiveRecord::Base; end

  class Permission < ActiveRecord::Base; end
  class Alberich::Permission < ActiveRecord::Base; end
  class DerivedPermission < ActiveRecord::Base; end
  class Alberich::DerivedPermission < ActiveRecord::Base; end

  def self.up
    bpo_map = {}
    bpo_metadata_objects = MetadataObject.where(:object_type => "BasePermissionObject")
    BasePermissionObject.all.each do |old_bpo|
      new_bpo = Alberich::BasePermissionObject.create!(:name => old_bpo.name)
      bpo_map[old_bpo.id] = new_bpo.id
      bpo_metadata_objects.select{|x| x.value.to_i == old_bpo.id}.each do |mobj|
        mobj.value = new_bpo.id.to_s
        mobj.object_type = "Alberich::BasePermissionObject"
        mobj.save!
      end
    end
    #entities should be automatically created by Alberich::Entity migration
    PermissionSession.all.each do |old_perm_session|
      new_perm_session = Alberich::PermissionSession.create!(:user_id =>
                                                   old_perm_session.user_id,
                                                             :session_id =>
                                                   old_perm_session.session_id)
      SessionEntity.where(:permission_session_id => new_perm_session.id).
        each do |old_session_entity|
        new_entity = new_entity_for_old(old_session_entity.entity_id)
        new_session_entity = Alberich::SessionEntity.
          create!(:user_id => old_session_entity.user_id,
                  :entity_id => new_entity.id,
                  :permission_session_id => new_perm_session.id)
      end
      
    end

    role_metadata_objects = MetadataObject.where(:object_type => "Role")
    Role.all.each do |old_role|
      new_role = Alberich::Role.create!(:name => old_role.name,
                                        :scope =>
                                          new_scope_for_old(old_role.scope),
                                        :assign_to_owner =>
                                          old_role.assign_to_owner)
      role_metadata_objects.select{|x| x.value.to_i == old_role.id}.each do |mobj|
        mobj.value = new_role.id.to_s
        mobj.object_type = "Alberich::Role"
        mobj.save!
      end
      Privilege.where(:role_id => old_role.id).each do |old_priv|
        new_priv = Alberich::Privilege.create!(:role_id => new_role.id,
                                               :target_type =>
                                                 new_scope_for_old(
                                                       old_priv.target_type),
                                               :action => old_priv.action)
      end
      Permission.where(:role_id => old_role.id).each do |old_perm|
        new_entity = new_entity_for_old(old_perm.entity_id)
        new_perm_obj = new_perm_obj_for_old(old_perm, bpo_map)
        new_perm = Alberich::Permission.
          create!(:role_id => new_role.id,
                  :entity_id => new_entity.id,
                  :permission_object_id => new_perm_obj.id,
                  :permission_object_type => new_perm_obj.class.name)
        DerivedPermission.where(:permission_id => old_perm.id).each do |old_derived_perm|
          new_derived_perm = Alberich::DerivedPermission.
            create!(:permission_id => new_perm.id,
                    :role_id => new_role.id,
                    :entity_id => new_entity.id,
                  :permission_object_id => new_perm_obj.id,
                  :permission_object_type => new_perm_obj.class.name)
        end
      end
    end

  end
  def new_entity_for_old(old_entity_id)
    old_entity = Entity.find(old_entity_id)
    new_entity = Alberich::Entity.where(:entity_target_type =>
                                        old_entity.entity_target_type,
                                        :entity_target_id =>
                                        old_entity.entity_target_id).first
    new_entity
  end
  def new_scope_for_old(old_scope)
    if old_scope == "BasePermissionObject"
      "Alberich::BasePermissionObject"
    else
      old_scope
    end
  end
  def new_perm_obj_for_old(old_perm, bpo_map)
    old_perm_obj = old_perm.permission_object_type.constantize.find(old_perm.permission_object_id)
    if old_perm.permission_object_type == "BasePermissionObject"
      Alberich::BasePermissionObject.find(bpo_map[old_perm_obj.id])
    else
      old_perm_obj
    end
  end
  def self.down
    Alberich::DerivedPermission.delete_all
    Alberich::Permission.delete_all
    Alberich::Privilege.delete_all
    Alberich::Role.delete_all
    Alberich::PermissionSession.delete_all
    Alberich::BasePermissionObject.delete_all
  end
end
