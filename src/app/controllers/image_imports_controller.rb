class ImageImportsController < ApplicationController
  before_filter :require_user

  def new
    init_provider_vars
  end

  def create
    begin
      LegacyImage.import(ProviderAccount.find(params[:provider_account_id]), params[:ami_id], current_user)
      flash[:notice]="Image successfully imported"
      redirect_to legacy_templates_path
    rescue Exception => e
      init_provider_vars
      # The full message may be multiple lines, including the actual request, so only include the first line:
      flash.now[:error]="Could not import image: #{e.message.split("\n").first}"
      Rails.logger.error([e.message,e.backtrace].join("\n  "))
      render :new
    end
  end

protected
def init_provider_vars
    @providers = Provider.list_for_user(current_user, Privilege::VIEW)
end
end
