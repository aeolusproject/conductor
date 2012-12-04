Tim::BaseImagesController.class_eval do
  before_filter :require_user

  before_filter :load_permissioned_images, :only => :index
  before_filter :check_view_permission, :only => [:show]
  before_filter :check_modify_permission, :only => [:edit, :update, :destroy]
  before_filter :check_create_permission, :only => [:new, :create]

  before_filter :set_tabs_and_headers, :only => [:index]
  before_filter :set_new_form_variables, :only => [:new]
  before_filter :set_image_versions, :only => :show
  before_filter :set_targets, :only => :show

  # FIXME: whole create method is overriden just because of
  # setting flash error and new_form_variables if creation fails
  def create
    @base_image = Tim::BaseImage.new(params[:base_image]) unless defined? @base_image
    if @base_image.save
      flash[:notice] = "Successfully created Base Image"
    else
      set_new_form_variables
      flash[:error] = @base_image.errors.full_messages
    end
    respond_with @base_image
  end

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
    @base_image ||= Tim::BaseImage.new(params[:base_image])
    # FIXME: remove this:
    @base_image.template ||= Tim::Template.new
    @accounts = @base_image.pool_family.provider_accounts.enabled.
      list_for_user(current_session, current_user, Privilege::USE)
    t("tim.base_images.flash.error.no_provider_accounts") if @accounts.empty?

    if @base_image.import and @base_image.image_versions.empty?
      @base_image.image_versions = [Tim::ImageVersion.new(
        :target_images => [Tim::TargetImage.new(
          :provider_images => [Tim::ProviderImage.new]
        )]
      )]
    end
  end

  def set_image_versions
    @versions = @base_image.image_versions.order('created_at DESC')
    @latest_version = @versions.first # because we sorted above
    # @version is the specific image version we're viewing
    @version = if params[:version]
      @versions.find{|v| v.id == params[:version]} || @latest_version
    else
      @latest_version
    end
  end

  def set_targets
    return [] unless @version # Otherwise, there's no point
    @targets = []

    # Preload up some data
    all_prov_accts = @base_image.pool_family.provider_accounts.includes(:provider => :provider_type)
    provider_types = available_provider_types_for_base_image(@base_image)
    target_images = @version.target_images(:include => :provider_images)
    
    # Run over all provider types
    provider_types.each do |provider_type|
      target_image = target_images.select{|ti| ti.provider_type_id == provider_type.id}.first
      _targetinfo = {
        :provider_type => provider_type,
        :target_image => target_image,
        :user_can_push => false, # some magic
        :user_can_delete => false, # some magic
        :provider_images => []
      }
      provider_accounts = accounts_for_provider_type(provider_type, all_prov_accts)
      provider_accounts.each do |provider_account|
        provider_image = target_image.provider_images.select{|pi| pi.factory_provider_account_id == provider_account.id}.first
        provider_image_data = {
          :provider_account => provider_account,
          :provider => provider_account.provider,
          :provider_image => provider_image
        }
        _targetinfo[:provider_images] << provider_image_data
      end
      @targets << _targetinfo
    end
  end

  private

  # We need this above. For a base image, find all _available_ ProviderTypes,
  # whether or not we have built for it.
  # This was too messy to do above, but feels too arcane to put in the BaseImage model,
  # especially since it's so tangentially related to BaseImages at all.
  def available_provider_types_for_base_image(base_image)
    all_types = []
    # Eager load all the data we'll need, rather than doing a bunch of one-off queries:
    prov_accts = @base_image.pool_family.provider_accounts.includes(:provider => :provider_type)
    prov_accts.each do |provider_account|
      type = provider_account.provider.provider_type
      all_types << type unless all_types.include?(type)
    end
    all_types
  end

  # Another weird one-off with no good home...
  # Find all provider accounts (in a given set, though we could look it up)
  # that have a given provider type.
  def accounts_for_provider_type(provider_type, provider_accounts)
    provider_accounts.select{|pa| pa.provider.provider_type_id == provider_type.id}
  end

end
