#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

class UsersController < ApplicationController
  before_filter :require_user, :except => [:new, :create]
  before_filter :load_users, :only => [:show]

  def index
    require_privilege(Privilege::VIEW, User)
    clear_breadcrumbs
    save_breadcrumb(users_path)
    @params = params
    load_headers
    load_users
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
    @user.quota ||= Quota.new

    @registration = RegistrationService.new(@user)
    unless @registration.save
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
    save_breadcrumb(user_path(@user), @user.name)
    @tab_captions = ['Properties']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    respond_to do |format|
      format.html
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab
      end
    end
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
      redirect_to user_path(@user)
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
    user = User.find(params[:id])
    if user == current_user
      flash[:warning] = "Cannot delete #{user.login}: you are logged in as this user"
    else
      user.destroy
    end

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

  def load_headers
    @header = [
      { :name => '', :sortable => false },
      { :name => t('users.index.user_id'), :sortable => false },
      { :name => t('users.index.last_name'), :sortable => false },
      { :name => t('users.index.first_name'), :sortable => false },
      { :name => t('users.index.quota_used'), :sortable => false },
      { :name => t('users.index.quota_instances'), :sortable => false },
      { :name => t('users.index.email'), :sortable => false },
    ]
  end

end
