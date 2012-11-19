class ImageImportsController < ApplicationController
  before_filter :require_user

  before_filter :check_create_permissions, :only => [:new, :create]

  respond_to :js, :html, :xml

  def new
    @accounts = @pool_family.provider_accounts.enabled.
      list_for_user(current_session, current_user, Privilege::USE)
    t("images.flash.error.no_provider_accounts_for_import") if @accounts.empty?
  end

  def create
    if @importer.import
      redirect_to tim.base_image_path(@importer.provider_image.image.id)
    else
      flash[:error] = @importer.errors.full_messages
      render :new
    end
  end

  private

  def check_create_permissions
    @importer = ImageImporter.new(params[:image_import])
    @pool_family = PoolFamily.find(@importer.pool_family_id)
    require_privilege(Privilege::CREATE, Tim::BaseImage, @pool_family)
  end
end
