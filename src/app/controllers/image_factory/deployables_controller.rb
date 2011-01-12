class ImageFactory::DeployablesController < ApplicationController
  before_filter :require_user
  before_filter :load_deployables, :only => [:index, :show]

  def index
  end

  def show
    @deployable = Deployable.find(params[:id])
    @url_params = params.clone
    @tab_captions = ['Properties']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
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
    @deployable = Deployable.new
  end

  def create
    @deployable = Deployable.new(params[:deployable])
    if @deployable.save
      flash[:notice] = "Deployable added."
      redirect_to image_factory_deployable_url(@deployable)
    else
      render :action => :new
    end
  end

  def edit
    @deployable = Deployable.find(params[:id])
  end

  def update
    @deployable = Deployable.find(params[:id])
    if @deployable.update_attributes(params[:deployable])
      flash[:notice] = "Deployable updated."
      redirect_to image_factory_deployable_url(@deployable)
    else
      render :action => :edit
    end
  end

  def multi_destroy
    Deployable.destroy(params[:deployables_selected])
    redirect_to image_factory_deployables_url
  end

  protected

  def load_deployables
    @header = [
      { :name => "Deployable name", :sort_attr => :name }
    ]
    @deployables = Deployable.paginate(:all,
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
    @url_params = params.clone
  end
end
