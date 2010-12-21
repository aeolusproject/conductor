class Resources::DeploymentsController < ApplicationController
  before_filter :require_user
  before_filter :load_deployments, :only => [:index, :show]

  def index
  end

  def show
    @tab_captions = ['Properties', 'Instances', 'Provider Services', 'Required Services', 'History', 'Permissions']
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

  private
  def load_deployments
    @url_params = params
    @header = [
      { :name => "Deployment name", :sort_attr => :name },
      { :name => "Deployable", :sortable => false },
      { :name => "Deployment Owner", :sort_attr => "owner.last_name"},
      { :name => "Running Since", :sort_attr => :running_since },
      { :name => "Heath Metric", :sort_attr => :health },
      { :name => "Pool", :sort_attr => "pool.name" }
    ]
  end
end