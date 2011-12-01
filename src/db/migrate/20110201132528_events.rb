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

class Events < ActiveRecord::Migration
  def self.up
    drop_table :instance_events
    create_table :events do |t|
      t.integer    :source_id, :null => false
      t.string     :source_type, :null => false
      t.datetime   :event_time
      t.string     :status_code
      t.string     :summary
      t.string     :description
      t.timestamps
    end
  end

  def self.down
    drop_table :events
    create_table :instance_events do |t|
      t.integer    :instance_id, :null => false
      t.string     :event_type,  :null => false
      t.datetime   :event_time
      t.string     :status
      t.string     :message
      t.timestamps
    end
  end
end
