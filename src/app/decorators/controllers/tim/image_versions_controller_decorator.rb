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

Tim::ImageVersionsController.class_eval do
  before_filter :require_user

  before_filter :load_permissioned_image_versions, :only => :index
  before_filter :check_view_permission, :only => [:show]
  before_filter :check_modify_permission, :only => [:edit, :update, :destroy]
  before_filter :check_create_permission, :only => [:new, :create]

  private

  def load_permissioned_image_versions
    images = Tim::BaseImage.list_for_user(current_session,
                                          current_user,
                                          Alberich::Privilege::VIEW)
    @image_versions = Tim::ImageVersion.where(:base_image_id => images.map{|i| i.id})
  end

  def check_view_permission
    @image_version = Tim::ImageVersion.find(params[:id])
    require_privilege(Alberich::Privilege::VIEW, @image_version.base_image)
  end

  def check_modify_permission
    @image_version = Tim::ImageVersion.find(params[:id])
    require_privilege(Alberich::Privilege::MODIFY, @image_version.base_image)
  end

  def check_create_permission
    @image_version = Tim::ImageVersion.new(params[:image_version])
    require_privilege(Alberich::Privilege::MODIFY, @image_version.base_image)
  end
end
