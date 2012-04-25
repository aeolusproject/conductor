#
#   Copyright 2011 Red Hat, Inc.
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

# == Schema Information
# Schema version: 20110207110131
#
# Table name: roles
#
#  id              :integer         not null, primary key
#  name            :string(255)     not null
#  scope           :string(255)     not null
#  lock_version    :integer         default(0)
#  created_at      :datetime
#  updated_at      :datetime
#  assign_to_owner :boolean
#

class Role < ActiveRecord::Base
  has_many :permissions, :dependent => :destroy
  has_many :derived_permissions, :dependent => :destroy
  has_many :privileges, :dependent => :destroy

  validates_presence_of :scope
  validates_presence_of :name
  validates_uniqueness_of :name

  validates_associated :privileges

  validates_length_of :name, :maximum => 255

  def privilege_target_types
    privileges.collect {|x| Kernel.const_get(x.target_type)}.uniq
  end
  def privilege_target_match(obj_type)
    (privilege_target_types & obj_type.active_privilege_target_types).any?
  end
end
