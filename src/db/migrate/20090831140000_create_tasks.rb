#
# Copyright (C) 2009 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.string    :user
      t.string    :type
      t.string    :action
      t.string    :state
      t.integer   :task_target_id
      t.string    :task_target_type
      t.string    :args
      t.timestamp :created_at
      t.timestamp :time_submitted
      t.timestamp :time_started
      t.timestamp :time_ended
      t.text      :message
      t.string    :failure_code
      t.integer   :lock_version, :default => 0
    end
  end

  def self.down
    drop_table :tasks
  end
end
