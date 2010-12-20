class Admin::UsersController < ApplicationController
  before_filter :require_user
  before_filter :only_admin, :only => [:index, :multi_destroy]
  before_filter :load_users, :only => [:index, :show]

  def new
    @user = User.new
    @user.quota = Quota.new
  end

  def create
    if params[:commit] == "Reset"
      redirect_to :action => 'new' and return
    end

    # TODO: Shouldn't it be if current_user.nil? instead?
    require_privilege(Privilege::USER_MODIFY) unless current_user.nil?
    @user = User.new(params[:user])

    @registration = RegistrationService.new(@user)
    unless @registration.save
      flash.now[:warning] = "User registration failed: #{@registration.error}"
      render :action => 'new' and return
    end

    if current_user
      flash[:notice] = "User registered!"
      redirect_to admin_users_url
    else
      flash[:notice] = "You have successfully registered!"
      redirect_to dashboard_url
    end
  end

  def show
    @user = User.find_by_id(params[:id]) || current_user
    @quota_resources = @user.quota.quota_resources
  end

  def edit
    @user = User.find_by_id(params[:id]) || current_user

    if cannot_modify_different_user?(@user)
      flash[:notice] = "Invalid Permission to perform this operation"
      redirect_to dashboard_url and return
    end
  end

  def update
    @user = User.find_by_id(params[:id]) || current_user

    if params[:commit] == "Reset"
      redirect_to edit_admin_user_url(@user) and return
    end

    redirect_to dashboard_url and return unless @user

    if cannot_modify_different_user = cannot_modify_different_user?(@user)
      flash[:notice] = "Invalid Permission to perform this operation"
      redirect_to dashboard_url and return
    end

    unless @user.update_attributes(params[:user])
      render :action => 'edit' and return
    else
      flash[:notice] = "User updated!"
      redirect_to cannot_modify_different_user ? dashboard_url : admin_users_url
    end
  end

  def multi_destroy
    User.destroy(params[:user_selected])
    redirect_to admin_users_url
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

  def only_admin
    unless current_user.permissions.collect { |p| p.role }.find { |r| r.name == "Administrator" }
      flash[:notice] = "Invalid Permission to perform this operation"
      redirect_to dashboard_url
    end
  end

  def cannot_modify_different_user?(user)
    user && user != current_user && !BasePermissionObject.general_permission_scope.can_modify_users(current_user)
  end

end
