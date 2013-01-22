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

  # @current_user must be defined

  def check_privilege(action, *type_and_perm_obj)
    target_type = nil
    perm_obj = nil
    type_and_perm_obj.each do |obj|
      target_type=obj if obj.class==Class
      perm_obj=obj if obj.is_a?(ActiveRecord::Base)
    end
    perm_obj=@perm_obj if perm_obj.nil?
    perm_obj=BasePermissionObject.general_permission_scope if perm_obj.nil?
    perm_obj.has_privilege(current_session, current_user, action, target_type)
  end

  # Require a given privilege level to view this page
  #   1. action is always required -- what action is being done (from Privilege::ACTIONS)
  #   2. perm_obj is optional -- This is the resource on which to look for permission
  #         records. If omitted, check for site-wide permissions on BasePermissionObject
  #   3. type is also optional -- if omitted it's taken from perm_obj.
  #        For example, if action is 'view', perm_obj is a Pool and type is omitted,
  #        then check for current user's "view pool" permission on this pool.
  #        if action is 'view', perm_obj is a Pool and type is Quota,
  #        then check for current user's "view quota" permission on this pool.
  def require_privilege(action, *type_and_perm_obj)
    perm_obj = nil
    type_and_perm_obj.each do |obj|
      perm_obj=obj if obj.is_a?(ActiveRecord::Base)
    end
    @perm_obj = perm_obj
    unless check_privilege(action, *type_and_perm_obj)
      raise PermissionError.new(
               _("You have insufficient privileges to perform the selected action."))
    end
  end
end
