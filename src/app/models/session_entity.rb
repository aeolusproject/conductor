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

class SessionEntity < ActiveRecord::Base
  belongs_to :user
  belongs_to :entity

  validates_presence_of :user_id
  validates_presence_of :session_id
  validates_presence_of :entity_id
  validates_uniqueness_of :entity_id, :scope => [:user_id, :session_id]

  def self.update_session(session_id, user)
    self.transaction do
      # skips callbacks, which should be fine here
      self.delete_all(:session_id => session_id)
      self.add_to_session(session_id, user)
    end
  end

  def self.add_to_session(session_id, user)
    return unless user
    # create mapping for user-level permissions
    SessionEntity.create!(:session_id => session_id, :user => user,
                          :entity => user.entity)
    # create mappings for local groups
    user.all_groups.each do |ug|
      SessionEntity.create!(:session_id => session_id, :user => user,
                            :entity => ug.entity)
    end
  end
end
