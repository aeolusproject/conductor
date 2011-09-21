#
# Copyright (C) 2011 Red Hat, Inc.
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

class TaskObserver < ActiveRecord::Observer

  END_STATES = [ Task::STATE_CANCELED, Task::STATE_FAILED, Task::STATE_FINISHED ]

  def before_save(a_task)
    if a_task.changed?
      change = a_task.changes['state']
      if change
        update_timestamp(change[0], change[1], a_task)
      end
    end
  end

  def update_timestamp(state_from, state_to, a_task)
    if state_to == Task::STATE_RUNNING
      a_task.time_started = Time.now
    elsif state_to == Task::STATE_PENDING
      a_task.time_submitted = Time.now
    elsif END_STATES.include?(state_to)
      a_task.time_ended = Time.now
    end
  end

end

TaskObserver.instance
