class DeployablesController < ApplicationController
  before_filter :require_user
  before_filter :load_deployables, :only => [:index, :show, :pick_assemblies]
  before_filter :load_deployable_with_assemblies, :only => [:remove_assemblies, :add_assemblies, :pick_assemblies]

  def index
    require_privilege(Privilege::VIEW, Template)
    @search_term = params[:q]
    return if @search_term.blank?
    search = Deployable.search() do
      keywords(params[:q])
    end
    @deployables = search.results
  end

  def show
    @deployable = Deployable.find(params[:id])
    require_privilege(Privilege::VIEW, @deployable)
    @url_params = params.clone
    @tab_captions = ['Properties', 'Assemblies', 'Deployments']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    if @details_tab == 'deployments'
      @deployments = @deployable.deployments
    end
    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.html { render :action => 'show'}
    end
  end

  def new
    require_privilege(Privilege::CREATE, Template)
    @deployable = Deployable.new
  end

  def create
    require_privilege(Privilege::CREATE, Template)
    @deployable = Deployable.new(params[:deployable])
    @deployable.owner = current_user
    if @deployable.save
      flash[:notice] = "Deployable added."
      redirect_to image_factory_deployable_url(@deployable)
    else
      render :action => :new
    end
  end

  def edit
    @deployable = Deployable.find(params[:id])
    require_privilege(Privilege::MODIFY, @deployable)
  end

  def update
    @deployable = Deployable.find(params[:id])
    require_privilege(Privilege::MODIFY, @deployable)
    if @deployable.update_attributes(params[:deployable])
      flash[:notice] = "Deployable updated."
      redirect_to image_factory_deployable_url(@deployable)
    else
      render :action => :edit
    end
  end

  def multi_destroy
    destroyed = []
    failed = []
    Deployable.find(params[:deployables_selected]).each do |deployable|
      if check_privilege(Privilege::MODIFY, deployable) and deployable.destroyable?
        deployable.destroy
        destroyed << deployable.name
      else
        failed << deployable.name
      end
    end

    unless destroyed.empty?
      flash[:notice] = t('deployables.index.deleted', :count => destroyed.length, :list => destroyed.join(', '))
    end
    unless failed.empty?
      flash[:error] = t('deployables.index.not_deleted', :count => failed.length, :list => failed.join(', '))
    end
    redirect_to image_factory_deployables_url
  end

  def pick_assemblies
    require_privilege(Privilege::MODIFY, @deployable)
    @assemblies = Assembly.all - @deployable.assemblies
    respond_to do |format|
      format.js { render :partial => 'pick_assemblies' }
      format.html { render 'pick_assemblies' }
    end
  end

  def add_assemblies
    require_privilege(Privilege::MODIFY, @deployable)
    if assemblies = params.delete(:assemblies_selected)
      @deployable.assembly_ids += assemblies.collect{|a| a.to_i}
      @deployable.save!
      flash[:notice] = "Assemblies saved."
    end
    respond_to do |format|
      format.js { render :partial => 'assemblies' }
      format.html { redirect_to image_factory_deployable_url(@deployable, :details_tab => 'assemblies') and return }
    end
  end

  def remove_assemblies
    require_privilege(Privilege::MODIFY, @deployable)
    if params[:assemblies_selected].present?
      @deployable.assembly_ids = @deployable.assembly_ids - params[:assemblies_selected].collect{|a| a.to_i}
      @deployable.save!
      flash[:notice] = "Assemblies removed."
    end
    respond_to do |format|
      format.js { render :partial => 'assemblies' }
      format.html { redirect_to image_factory_deployable_url(@deployable, :details_tab => 'assemblies') and return }
    end
  end

  protected

  def load_deployables
    @header = [
      { :name => "Deployable name", :sort_attr => :name }
    ]
    @header_deployments = [
      { :name => "Deployment name", :sort_attr => :name },
      { :name => "Deployable", :sortable => false },
      { :name => "Deployment Owner", :sort_attr => "owner.last_name"},
      { :name => "Running Since", :sort_attr => :running_since },
      { :name => "Heath Metric", :sort_attr => :health },
      { :name => "Pool", :sort_attr => "pool.name" }
    ]
    @deployables = Deployable.paginate(:all,
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
    @url_params = params.clone
  end

  def load_deployable_with_assemblies
    @deployable = Deployable.find(params[:id], :include => :assemblies)
  end
end
