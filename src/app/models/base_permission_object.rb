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
# Table name: base_permission_objects
#
#  id         :integer         not null, primary key
#  name       :string(255)     not null
#  created_at :datetime
#  updated_at :datetime
#

class BasePermissionObject < ActiveRecord::Base

  include PermissionedObject
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"

  validates_presence_of :name
  validates_uniqueness_of :name

  GENERAL_PERMISSION_SCOPE = "general_permission_scope"

  def self.general_permission_scope
    base_permission = self.find_by_name(GENERAL_PERMISSION_SCOPE)
    base_permission = self.create!(:name => GENERAL_PERMISSION_SCOPE) unless base_permission
    base_permission
  end
end
