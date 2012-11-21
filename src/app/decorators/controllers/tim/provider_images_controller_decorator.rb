Tim::ProviderImagesController.class_eval do
  before_filter :require_user

  before_filter :load_permissioned_provider_images, :only => :index
  before_filter :check_view_permission, :only => [:show]
  before_filter :check_modify_permission, :only => [:edit, :update, :destroy]
  before_filter :check_create_permission, :only => [:new, :create]

  private

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
    require_privilege(Privilege::CREATE, Tim::ProviderImage,
                      @provider_image.base_image.pool_family)
  end
end
