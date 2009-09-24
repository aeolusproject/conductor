class ProviderController < ApplicationController
  before_filter :require_user

  def index
    render :action => 'new'
  end

  def show
    @provider = Provider.find(:first, :conditions => {:id => params[:id]})
  end

  def new
    @provider = Provider.new(params[:provider])
    if request.post? && @provider.save && @provider.populate_flavors
      flash[:notice] = "Provider added."
      redirect_to :action => "show", :id => @provider
    end
  end

  def destroy
    if request.post?
      p =Provider.find(params[:provider][:id])
      p.destroy
    end
    redirect_to :action => "index"
  end

end
