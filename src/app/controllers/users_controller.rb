#
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class UsersController < ApplicationController
  before_filter :require_user, :only => [:show, :edit, :update, :index, :destroy]
  before_filter :current_user

  def new
    require_privilege(Privilege::CREATE, User) unless current_user.nil?
    @user = User.new
    @user.quota = Quota.new
  end

  def create
    require_privilege(Privilege::CREATE, User) unless current_user.nil?
    @user = User.new(params[:user])

    if params[:commit] == "Reset"
      redirect_to :action => :new
      return
    end

    @registration = RegistrationService.new(@user)
    if @registration.save
      if @current_user
        flash[:notice] = "User registered!"
        redirect_to users_path
      else
        flash[:notice] = "You have successfully registered!"
        redirect_to :dashboard
      end
    else
      flash[:warning] = "user registration failed: #{@registration.error}"
      render :action => :new
    end
  end

  def show
    if params.has_key?(:id) && params[:id] != "show"
      @user = User.find(params[:id])
    else
      @user = current_user
    end
    require_privilege(Privilege::VIEW, User) unless current_user == @user
    @quota_resources = @user.quota.quota_resources()
  end

  def edit
    @user = params[:id] ? User.find(params[:id]) : current_user
    require_privilege(Privilege::MODIFY, User) unless current_user == @user
  end

  def update
    @user = params[:user][:id] ? User.find(params[:user][:id]) : @current_user
    require_privilege(Privilege::MODIFY, User) unless current_user == @user
    if params[:commit] == "Save"
      if @user
        if @user.update_attributes(params[:user])
          flash[:notice] = "User updated!"
          if @user == current_user
            redirect_to :dashboard
          else
            redirect_to users_path
          end
        else
          render :action => :edit
        end
      end
    elsif params[:commit] == "Reset"
      redirect_to :action => "edit", :id => @user.id
    end
  end

  def index
    require_privilege(Privilege::VIEW, User)
    @users = User.all
    sort_order = params[:sort_by].nil? ? "login" : params[:sort_by]
    if sort_order == "percentage_quota_used"
      @users = User.all
      @users.sort! {|x,y| y.quota.percentage_used <=> x.quota.percentage_used }
    elsif sort_order == "quota"
      @users = User.all
      @users.sort! {|x,y| (x.quota.maximum_running_instances and y.quota.maximum_running_instances) ? x.quota.maximum_running_instances <=> y.quota.maximum_running_instances : (x ? 1 : -1) }
    else
      @users = User.find(:all, :order => sort_order)
    end
  end

  def manage_user
    @current_user = current_user
    type = params[:commit]
    user_id = params[:user_checkbox]
    if type && User.exists?(user_id)
      if type == "edit"
        redirect_to :action => 'edit', :id => user_id
      elsif type == "delete"
        params[:id] = user_id
        destroy
      end
    else
      flash[:notice] = "Error performing this operation"
      redirect_to users_path
    end
  end

  def destroy
    require_privilege(Privilege::MODIFY, User)
    if request.post? || request.delete?
      @user = User.find(params[:id])
      if @user == @current_user
        flash[:notice] = "Can not delete the currently logged in user!"
      elsif @user.destroy
        flash[:notice] = "User Deleted"
      else
        flash[:error] = {
          :summary => "Failed to delete User",
          :failures => @user.errors.full_messages,
        }
      end
    end
    redirect_to users_path
  end

  def section_id
    "loginpage"
  end
end
