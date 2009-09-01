#
# Copyright (C) 2009 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>,
#            David Lutterkort <lutter@redhat.com>
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
#
# Common infrastructure for business logic for WUI and QMF
#
# We call objects in the mid-level API 'Service' for lack of a better name.
# The Service layer is all in modules that are included by the classes that
# use them in the WUI and the QMF controllers. They set instance variables,
# which automatically become instance variables on the controllers that use
# the Service modules

module ApplicationService
  class PermissionError < RuntimeError; end
  class ActionError < RuntimeError; end
  class PartialSuccessError < RuntimeError
    attr_reader :failures, :successes
    def initialize(msg, failures={}, successes=[])
      @failures = failures
      @successes = successes
      super(msg)
    end
  end

  # Including class must provide a GET_LOGIN_USER

  def set_perms(perm_obj)
    #FIXME: define perms for deltacloud
  end

  def authorized?(privilege, perm_obj=nil)
    #FIXME: define perms for deltacloud
    return true
  end
  def authorized!(privilege, perm_obj=nil)
    unless authorized?(privilege, perm_obj)
      raise PermissionError.new(
               'You have insufficient privileges to perform action.')
    end
  end

end
