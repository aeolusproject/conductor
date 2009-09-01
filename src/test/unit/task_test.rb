#
# Copyright (C) 2008 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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

require File.dirname(__FILE__) + '/../test_helper'

class TaskTest < ActiveSupport::TestCase
  fixtures :tasks

  def setup
    @task = Task.new( :type => 'InstanceTask', :state => 'finished' )
  end

  def test_valid_fails_with_bad_type
    @task.type = 'foobar'
    flunk 'Task must specify valid type' if @task.valid?
  end

  def test_valid_fails_with_bad_state
    @task.state = 'foobar'
    flunk 'Task must specify valid state' if @task.valid?
  end

  def test_exercise_task_relationships
    #assert_equal tasks(:shutdown_production_httpd_appliance_task).task_target.vm_resource_pool.name, 'corp.com production vmpool'
    #assert_equal tasks(:shutdown_production_httpd_appliance_task).task_target.host.hostname, 'prod.corp.com'
  end

end
