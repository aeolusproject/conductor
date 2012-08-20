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
  belongs_to :permission_session

  validates_presence_of :user_id
  validates_presence_of :permission_session_id
  validates_presence_of :entity_id
  validates_uniqueness_of :entity_id, :scope => [:user_id, :permission_session_id]

end
