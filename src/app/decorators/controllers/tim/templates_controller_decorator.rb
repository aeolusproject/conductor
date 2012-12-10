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

Tim::TemplatesController.class_eval do
  before_filter :require_user

  before_filter :load_permissioned_templates, :only => :index
  before_filter :check_view_permission, :only => [:show]
  before_filter :check_modify_permission, :only => [:edit, :update, :destroy]
  before_filter :check_create_permission, :only => [:new, :create]

  private

  def load_permissioned_templates
    @templates = Tim::Template.list_for_user(current_session,
                                                current_user,
                                                Privilege::VIEW)
  end

  def check_view_permission
    @template = Tim::Template.find(params[:id])
    require_privilege(Privilege::VIEW, @template)
  end

  def check_modify_permission
    @template = Tim::Template.find(params[:id])
    require_privilege(Privilege::MODIFY, @template)
  end

  def check_create_permission
    @template = Tim::Template.new(params[:template])
    require_privilege(Privilege::CREATE, Tim::Template, @template.pool_family)
  end
end
