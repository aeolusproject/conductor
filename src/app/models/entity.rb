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

class Entity < ActiveRecord::Base
  belongs_to :entity_target, :polymorphic => true
  validates_presence_of :entity_target_id
  has_many :session_entities, :dependent => :destroy
  has_many :permissions, :dependent => :destroy
  has_many :derived_permissions, :dependent => :destroy

  # type-specific associations
  belongs_to :user, :class_name => "User", :foreign_key => "entity_target_id"
  belongs_to :user_group, :class_name => "UserGroup",
                          :foreign_key => "entity_target_id"

end
