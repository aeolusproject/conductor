class RealmsController < ApplicationController
  before_filter :require_user
  before_filter :load_realms, :only =>[:index, :show]

  def top_section
    :administer
  end

  def index
    clear_breadcrumbs
    save_breadcrumb(realms_path)
  end

  def new
    require_privilege(Privilege::CREATE, Realm)
    @realm = FrontendRealm.new
    load_backend_realms
  end

  def edit
    require_privilege(Privilege::MODIFY, Realm)
    @realm = FrontendRealm.find(params[:id])
    load_backend_realms
  end

  def update
    require_privilege(Privilege::MODIFY, Realm)
    @realm = FrontendRealm.find(params[:id])

    if params[:commit] == "Reset"
      redirect_to edit_realm_url(@realm) and return
    end

    if @realm.update_attributes(params[:frontend_realm])
      flash[:notice] = 'Realm updated successfully!'
      redirect_to realms_url and return
    end

    load_backend_realms
    render :action => 'edit'
  end

  def create
    require_privilege(Privilege::CREATE, Realm)
    @realm = FrontendRealm.new(params[:frontend_realm])
    if @realm.save
      flash[:notice] = "Realm was added."
      redirect_to realms_path and return
    end

    load_backend_realms
    render :new
  end

  def destroy
    require_privilege(Privilege::MODIFY, Realm)
    if FrontendRealm.destroy(params[:id])
      flash[:notice] = "Realm was deleted!"
    else
      flash[:error] = "Realm was not deleted!"
    end
    redirect_to realms_path
  end

  def multi_destroy
    deleted = []
    not_deleted = []
    if params[:realm_selected].blank?
      flash[:error] = 'You must select at least one realm to delete.'
    else
      FrontendRealm.find(params[:realm_selected]).each do |realm|
        require_privilege(Privilege::MODIFY, Realm)
        if realm.destroy
          deleted << realm.name
        else
          not_deleted << realm.name
        end
      end
    end

    unless deleted.empty?
      flash[:notice] = "These Realms were deleted: #{deleted.join(', ')}"
    end
    unless not_deleted.empty?
      flash[:error] = "Could not deleted these Realms: #{not_deleted.join(', ')}"
    end
    redirect_to realms_path
  end

  def show
    @realm = FrontendRealm.find(params[:id])

    @tab_captions = ['Properties', 'Mapping']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]

    @backend_realm_targets = @realm.realm_backend_targets.select { |x| x.realm_or_provider_type == 'Realm' }
    @backend_provider_targets = @realm.realm_backend_targets.select { |x| x.realm_or_provider_type == 'Provider' }

    save_breadcrumb(realm_path(@realm), @realm.name)

    respond_to do |format|
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab
      end
      format.html { render :action => 'show' }
    end
  end

  protected

  def load_backend_realms
    #TODO: list only realms user has permission on
    @backend_realms = Realm.all
    @providers = Provider.list_for_user(current_user, Privilege::VIEW)
  end

  def load_realms
    @header = [
      {:name => '', :sortable => false},
      {:name => t("realms.index.realm_name"), :sort_attr => :name},
    ]
    @realms = FrontendRealm.all
  end
end
