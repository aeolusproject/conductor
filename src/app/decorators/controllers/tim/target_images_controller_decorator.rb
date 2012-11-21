Tim::TargetImagesController.class_eval do
  before_filter :require_user

  before_filter :load_permissioned_target_images, :only => :index
  before_filter :check_view_permission, :only => [:show]
  before_filter :check_modify_permission, :only => [:edit, :update, :destroy]
  before_filter :check_create_permission, :only => [:new, :create]

  private

  def load_permissioned_target_images
    images = Tim::BaseImage.list_for_user(current_session,
                                          current_user,
                                          Privilege::VIEW)
    @target_images = Tim::TargetImage.find_by_images(images)
  end

  def check_view_permission
    @target_image = Tim::TargetImage.find(params[:id])
    require_privilege(Privilege::VIEW, @target_image.base_image)
  end

  def check_modify_permission
    @target_image = Tim::TargetImage.find(params[:id])
    require_privilege(Privilege::MODIFY, @target_image.base_image)
  end

  def check_create_permission
    @target_image = Tim::TargetImage.new(params[:target_image])
    require_privilege(Privilege::CREATE, Tim::TargetImage,
                      @target_image.base_image.pool_family)
  end
end
