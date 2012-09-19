#
#   Copyright 2012 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
class CreateEntities < ActiveRecord::Migration
  def self.up
    create_table :entities do |t|
      t.string :name
      t.references :entity_target, :polymorphic => true, :null => false

      t.integer :lock_version, :default => 0

      t.timestamps
    end

    User.all.each do |u|
      unless u.entity
        entity = Entity.new(:entity_target => u)
        entity.name = "#{u.first_name} #{u.last_name} (#{u.login})"
        entity.save!
      end
    end
    UserGroup.all.each do |ug|
      unless ug.entity
        entity = Entity.new(:entity_target => ug)
        entity.name = "#{ug.name} (#{ug.membership_source})"
        entity.save!
      end
    end
  end

  def self.down
    drop_table :entities
  end
end
