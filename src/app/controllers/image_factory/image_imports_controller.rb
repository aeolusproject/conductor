class ImageFactory::ImageImportsController < ApplicationController
  before_filter :require_user

  def new
    init_provider_vars
  end

  def create
    begin
      Image.import(ProviderAccount.find(params[:provider_account_id]), params[:ami_id])
      flash[:notice]="Image successfully imported"
      redirect_to image_factory_templates_path
      kick_condor
    rescue => e
      init_provider_vars
      flash.now[:error]=e.message
      Rails.logger.error([e.message,e.backtrace].join("\n  "))
      render :new
    end
  end

protected
def init_provider_vars
    @providers = Provider.list_for_user(current_user, Privilege::VIEW)
end
end
