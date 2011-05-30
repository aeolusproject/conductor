class ProviderTypesController < ApplicationController
  before_filter :require_user

  def index
    @provider_types = ProviderType.all
    respond_to do |format|
      format.xml { render :partial => 'list.xml' }
    end
  end
end
