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
                                          Privilege::VIEW)
    @image_versions = Tim::ImageVersion.where(:base_image_id => images.map{|i| i.id})
  end

  def check_view_permission
    @image_version = Tim::ImageVersion.find(params[:id])
    require_privilege(Privilege::VIEW, @image_version.image)
  end

  def check_modify_permission
    @image_version = Tim::ImageVersion.find(params[:id])
    require_privilege(Privilege::MODIFY, @image_version.image)
  end

  def check_create_permission
    @image_version = Tim::ImageVersion.new(params[:image_version])
    require_privilege(Privilege::CREATE, Tim::ImageVersion,
                      @image_version.image.pool_family)
  end
end
