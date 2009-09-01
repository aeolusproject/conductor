#
# Copyright (C) 2009 Red Hat, Inc.
# Written by Jason Guiditta <jguiditt@redhat.com>
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

class VmTaskTest < ActiveSupport::TestCase

  fixtures :vms

  # Ensure action_privilege method returns nil if it is passed an action
  # that does not exist.
  def test_action_privilege_with_bad_action
    assert_equal(nil, VmTask.action_privilege('stop_vm'))
  end

  # Ensure action_privilege_object method returns nil if it is passed an action
  # that does not exist.
  def test_action_privilege_object_with_bad_action
    assert_equal(nil, VmTask.action_privilege_object('stop_vm', vms(:production_httpd_vm).id))
  end
end
