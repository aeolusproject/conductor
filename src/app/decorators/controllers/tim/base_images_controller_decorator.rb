Tim::BaseImagesController.class_eval do
  before_filter :require_user

  before_filter :load_permissioned_images, :only => :index
  before_filter :check_view_permission, :only => [:show]
  before_filter :check_modify_permission, :only => [:edit, :update, :destroy]
  before_filter :check_create_permission, :only => [:new, :create]

  private

  def load_permissioned_images
    @base_images = Tim::BaseImage.list_for_user(current_session,
                                                current_user,
                                                Privilege::VIEW)
  end

  def check_view_permission
    @base_image = Tim::BaseImage.find(params[:id])
    require_privilege(Privilege::VIEW, @base_image)
  end

  def check_modify_permission
    @base_image = Tim::BaseImage.find(params[:id])
    require_privilege(Privilege::MODIFY, @base_image)
  end

  def check_create_permission
    @base_image = Tim::BaseImage.new(params[:base_image])
    require_privilege(Privilege::CREATE, Tim::BaseImage, @base_image.pool_family)
  end
end
