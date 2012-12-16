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

Tim::ProviderImagesController.class_eval do
  before_filter :require_user

  before_filter :load_permissioned_provider_images, :only => :index
  before_filter :check_view_permission, :only => [:show]
  before_filter :check_modify_permission, :only => [:edit, :update, :destroy]
  before_filter :check_create_permission, :only => [:new, :create]
  before_filter :redirect_to_base_image, :only => [:create, :destroy]

  private

  def redirect_to_base_image
    @respond_options = {
      :location  => tim.base_image_path(@provider_image.base_image),
      :responder => Tim::RedirResponder
    } if request.format == :html
  end

  def load_permissioned_provider_images
    images = Tim::BaseImage.list_for_user(current_session,
                                          current_user,
                                          Privilege::VIEW)
    @provider_images = Tim::ProviderImage.find_by_images(images)
  end

  def check_view_permission
    @provider_image = Tim::ProviderImage.find(params[:id])
    require_privilege(Privilege::VIEW, @provider_image.base_image)
  end

  def check_modify_permission
    @provider_image = Tim::ProviderImage.find(params[:id])
    require_privilege(Privilege::MODIFY, @provider_image.base_image)
  end

  def check_create_permission
    @provider_image = Tim::ProviderImage.new(params[:provider_image])
    require_privilege(Privilege::MODIFY, @provider_image.base_image)
  end
end
