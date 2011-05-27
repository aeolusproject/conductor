class RealmMappingsController < ApplicationController
  before_filter :require_user
  layout 'application'

  def top_section
    :administer
  end

  def new
    require_privilege(Privilege::CREATE, Realm)
    @realm_target = RealmBackendTarget.new(:frontend_realm_id => params[:frontend_realm_id], :realm_or_provider_type => params[:realm_or_provider_type])
    load_backend_targets
  end

  def create
    require_privilege(Privilege::CREATE, Realm)
    @realm_target = RealmBackendTarget.new(params[:realm_backend_target])
    if @realm_target.save
      flash[:notice] = "Realm mapping was added."
      redirect_to realm_path(@realm_target.frontend_realm, :details_tab => 'mapping') and return
      #redirect_to realms_path and return
    end

    load_backend_targets
    render :new
  end

  def multi_destroy
    require_privilege(Privilege::MODIFY, Realm)
    if params[:id].blank?
      flash[:error] = 'You must select at least one mapping to delete.'
      redirect_to realm_path(params[:frontend_realm_id], :details_tab => 'mapping')
    else
      # TODO: add permissions checks
      destroyed = RealmBackendTarget.destroy(params[:id])
      redirect_to realm_path(destroyed.first.frontend_realm_id, :details_tab => 'mapping')
    end
  end

  protected

  def load_backend_targets
    @backend_targets = @realm_target.realm_or_provider_type == 'Realm' ? Realm.all : Provider.list_for_user(@current_user, Privilege::VIEW)
  end
end
