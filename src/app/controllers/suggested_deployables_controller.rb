class SuggestedDeployablesController < ApplicationController
  before_filter :require_user
  layout 'application'

  def top_section
    :administer
  end

  def index
    @suggested_deployables = SuggestedDeployable.list_for_user(current_user, Privilege::VIEW)
    set_header
  end

  def new
    @suggested_deployable = SuggestedDeployable.new(params[:suggested_deployable])
    require_privilege(Privilege::CREATE, SuggestedDeployable)
  end

  def show
    @suggested_deployable = SuggestedDeployable.find(params[:id])
    require_privilege(Privilege::VIEW, @suggested_deployable)
  end

  def create
    if params[:cancel]
      redirect_to suggested_deployables_path
      return
    end

    require_privilege(Privilege::CREATE, SuggestedDeployable)
    @suggested_deployable = SuggestedDeployable.new(params[:suggested_deployable])
    @suggested_deployable.owner = current_user
    if @suggested_deployable.save
      flash[:notice] = 'Deployable added'
      redirect_to suggested_deployables_path
    else
      render :new
    end
  end

  def edit
    @suggested_deployable = SuggestedDeployable.find(params[:id])
    require_privilege(Privilege::MODIFY, @suggested_deployable)
  end

  def update
    @suggested_deployable = SuggestedDeployable.find(params[:id])
    require_privilege(Privilege::MODIFY, @suggested_deployable)
    params[:suggested_deployable].delete(:owner_id) if params[:suggested_deployable]

    if @suggested_deployable.update_attributes(params[:suggested_deployable])
      flash[:notice] = 'Deployable updated successfully!'
      redirect_to suggested_deployables_url
    else
      render :action => 'edit'
    end
  end

  def multi_destroy
    SuggestedDeployable.find(params[:suggested_deployables_selected]).to_a.each do |d|
      require_privilege(Privilege::MODIFY, d)
      d.destroy
    end
    redirect_to suggested_deployables_path
  end

  private

  def set_header
    @header = [
      { :name => '', :sortable => false },
      { :name => t("suggested_deployables.index.name"), :sort_attr => :name },
      { :name => t("suggested_deployables.index.url"), :sortable => :url }
    ]
  end
end
