# This migration comes from alberich (originally 20121027023136)
class CreateAlberichEntities < ActiveRecord::Migration
  class Alberich::Entity < ActiveRecord::Base; end

  def up
    create_table :alberich_entities do |t|
      t.string :name
      t.references :entity_target, :polymorphic => true, :null => false

      t.integer :lock_version, :default => 0
      t.timestamps
    end
    if Alberich.user_class.constantize.table_exists?
      Alberich.user_class.constantize.all.each do |u|
        unless Alberich::Entity.where(:entity_target_type =>
                                        Alberich.user_class,
                                        :entity_target_id =>
                                        u.id).first
          entity = Alberich::Entity.new(:entity_target_id => u.id,
                                        :entity_target_type =>
                                        Alberich.user_class)
          entity.name = u.to_s
          entity.save!
        end
      end
    end
    if Alberich.user_group_class.constantize.table_exists?
      Alberich.user_group_class.constantize.all.each do |ug|
        unless Alberich::Entity.where(:entity_target_type =>
                                        Alberich.user_group_class,
                                        :entity_target_id =>
                                        ug.id).first
          entity = Alberich::Entity.new(:entity_target_id => ug.id,
                                        :entity_target_type =>
                                        Alberich.user_group_class)
          entity.name = ug.to_s
          entity.save!
        end
      end
    end
  end
  def down
    drop_table :alberich_entities
  end
end
