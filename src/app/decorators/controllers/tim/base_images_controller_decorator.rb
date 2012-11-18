Tim::BaseImagesController.class_eval do
  before_filter :require_user

  before_filter :load_permissioned_images, :only => :index
  before_filter :check_view_permission, :only => [:show]
  before_filter :check_modify_permission, :only => [:edit, :update, :destroy]
  before_filter :check_create_permission, :only => [:new, :create]

  before_filter :set_tabs_and_headers, :only => [:index]
  before_filter :set_new_form_variables, :only => [:new]

 def edit_xml
    @base_image = Tim::BaseImage.new(params[:base_image])

    #TODO: template fetching sets image.errors
    if @base_image.errors.present? or !@base_image.valid?
      flash.now[:error] = @base_image.errors.full_messages
      # if only error is with template XMl, go to edit_xml page
      if @base_image.errors.count == 1 && @base_image.errors['template.xml'].present?
        @base_image.template ||= Tim::Template.new
        render :edit_xml
      else
        set_new_form_variables
        render :new
      end
      return
    end

    render :overview unless params[:edit]
  end

 def overview
    @base_image = Tim::BaseImage.new(params[:base_image])
    unless @base_image.valid?
      @base_image.template ||= Tim::Template.new
      flash.now[:error] = @base_image.errors.full_messages
      render :edit_xml
      return
    end
 end

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

  def set_tabs_and_headers
    set_admin_environments_tabs 'images'
    @header = [
      { :name => t('tim.base_images.index.name'), :sort_attr => :name },
      { :name => t('tim.base_images.index.environment_header'), :sort_attr => :name },
      { :name => t('tim.base_images.index.os'), :sort_attr => :name },
      { :name => t('tim.base_images.index.os_version'), :sort_attr => :name },
      { :name => t('tim.base_images.index.architecture'), :sort_attr => :name },
      { :name => t('tim.base_images.index.last_rebuild'), :sortable => false },
    ]
  end

  def set_new_form_variables
    @base_image = Tim::BaseImage.new(params[:base_image])
    # FIXME: remove this:
    @base_image.template ||= Tim::Template.new
    @accounts = @base_image.pool_family.provider_accounts.enabled.
      list_for_user(current_session, current_user, Privilege::USE)
    if @accounts.empty?
      flash.now[:error] = params[:tab] == 'import' ?
        t("tim.base_images.flash.error.no_provider_accounts_for_import") :
        t("tim.base_images.flash.error.no_provider_accounts")
    end
  end
end
