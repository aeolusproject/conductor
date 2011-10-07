require 'rest_client'

class ConfigServersController < ApplicationController
  before_filter :require_user
  layout 'application'

  def top_section
    :administer
  end

  def edit
    @config_server = ConfigServer.find(params[:id])
    @provider_account = @config_server.provider_account
    require_privilege(Privilege::MODIFY, @provider_account)
  end

  def new
    @provider_account = ProviderAccount.find(params[:provider_account_id])
    require_privilege(Privilege::MODIFY, @provider_account)
    @config_server = ConfigServer.new()
  end

  def test
    config_server = ConfigServer.find(params[:id])
    if not config_server.connection_valid?
      flash[:error] = config_server.connection_error_msg
    else
      flash[:notice] = "Test successful"
    end
    provider_account = config_server.provider_account
    provider = provider_account.provider
    redirect_to provider_provider_account_path(provider, provider_account)
  end

  def create
    @provider_account = ProviderAccount.find(params[:provider_account_id])
    # for now the privileges required to create, modify, or delete a config
    # server are tied to modifying the particular associated provider account
    require_privilege(Privilege::MODIFY, @provider_account)

    @config_server = ConfigServer.new(params[:config_server])
    @config_server.provider_account = @provider_account
    if @config_server.invalid?
      flash[:error] = "The config server information is invalid."
      render :action => 'new' and return
    end
    @config_server.save!
    flash[:notice] = "Config server added."
    redirect_to provider_provider_account_path(@provider_account.provider, @provider_account)
  end

  def update
    @config_server = ConfigServer.find(params[:id])
    @provider_account = @config_server.provider_account
    require_privilege(Privilege::MODIFY, @provider_account)

    if @config_server.update_attributes(params[:config_server])
      flash[:notice] = "Config server updated."
      redirect_to provider_provider_account_path(@provider_account.provider, @provider_account)
    else
      flash[:error] = "Config server was not updated"
      render :action => :edit
    end
  end

  def destroy
    @config_server = ConfigServer.find(params[:id])
    require_privilege(Privilege::MODIFY, @config_server.provider_account)
    if ConfigServer.destroy(params[:id])
      flash[:notice] = "Config server was deleted."
    else
      flash[:error] = "Config server was not deleted"
    end
    provider_account = @config_server.provider_account
    provider = provider_account.provider
    redirect_to provider_provider_account_path(provider, provider_account)
  end
end
