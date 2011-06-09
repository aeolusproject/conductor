class UsersController < ApplicationController
  before_filter :require_user, :except => [:new, :create]
  before_filter :load_users, :only => [:show]
  layout 'application'

  def top_section
    :administer
  end

  def index
    clear_breadcrumbs
    require_privilege(Privilege::VIEW, User)
    save_breadcrumb(users_path, "Users")
    @params = params
    @search_term = params[:q]
    if @search_term.blank?
      load_users
      return
    end

    search = User.search do
      keywords(params[:q])
    end
    @users = search.results
  end

  def new
    require_privilege(Privilege::CREATE, User) unless current_user.nil?
    @user = User.new
    @user.quota = Quota.new
  end

  def create
    if params[:commit] == "Reset"
      redirect_to :action => 'new' and return
    end

    require_privilege(Privilege::MODIFY, User) unless current_user.nil?
    @user = User.new(params[:user])

    @registration = RegistrationService.new(@user)
    unless @registration.save
      flash.now[:warning] = "User registration failed: #{@registration.error}"
      render :action => 'new' and return
    end

    if current_user != @user
      flash[:notice] = "User registered!"
      redirect_to users_url
    else
      flash[:notice] = "You have successfully registered!"
      redirect_to root_url
    end
  end

  def show
    @user = params[:id] ? User.find(params[:id]) : current_user
    require_privilege(Privilege::VIEW, User) unless current_user == @user
    @quota_resources = @user.quota.quota_resources

    @url_params = params.clone
    @tab_captions = ['Properties']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab
      end
      format.html
    end
    save_breadcrumb(user_path(@user), [@user.first_name, @user.last_name].join(' ').titlecase)
  end

  def edit
    @user = params[:id] ? User.find(params[:id]) : current_user
    require_privilege(Privilege::MODIFY, User) unless @user == current_user
  end

  def update
    @user = params[:id] ? User.find(params[:id]) : current_user
    require_privilege(Privilege::MODIFY, User) unless @user == current_user

    if params[:commit] == "Reset"
      redirect_to edit_user_url(@user) and return
    end

    redirect_to root_url and return unless @user

    unless @user.update_attributes(params[:user])
      render :action => 'edit' and return
    else
      flash[:notice] = "User updated!"
      redirect_to (@user == current_user) ? root_url : users_url
    end
  end

  def multi_destroy
    require_privilege(Privilege::MODIFY, User)
    deleted_users = []
    User.find(params[:user_selected]).each do |user|
      if user == current_user
        flash[:warning] = "Cannot delete #{user.login}: you are logged in as this user"
      else
        user.destroy
        deleted_users << user.login
      end
    end
    unless deleted_users.empty?
      msg = "Deleted user#{'s' if deleted_users.length > 1}"
      flash[:notice] =  "#{msg}: #{deleted_users.join(', ')}"
    end
    redirect_to users_url
  end

  def destroy
    require_privilege(Privilege::MODIFY, User)
    User.destroy(params[:id])

    respond_to do |format|
      format.html { redirect_to users_path }
    end
  end

  protected

  def load_users
    @users = User.all
    sort_order = params[:sort_by].nil? ? "login" : params[:sort_by]
    # TODO: (lmartinc) Optimize this sort! hell!
    if sort_order == "percentage_quota_used"
      @users.sort! {|x,y| y.quota.percentage_used <=> x.quota.percentage_used }
    elsif sort_order == "quota"
      @users.sort! {|x,y| (x.quota.maximum_running_instances and y.quota.maximum_running_instances) ? x.quota.maximum_running_instances <=> y.quota.maximum_running_instances : (x ? 1 : -1) }
    else
      @users = User.all(:order => sort_order)
    end
  end

end
