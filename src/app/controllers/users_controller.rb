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
  before_filter :current_user, :only => [:new, :index, :destroy]

  def new
    @user = User.new
  end

  def create
    require_privilege(Privilege::USER_MODIFY) unless current_user.nil?
    @user = User.new(params[:user])

    @registration = RegistrationService.new(@user)
    if @registration.save
      flash[:notice] = "User registered!"
      redirect_back_or_default user_url(@user)
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
  end

  def edit
    @user = @current_user
  end

  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "User updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end

  def index
    if @current_user.permissions.collect { |p| p.role }.find { |r| r.name == "Administrator" }
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
    else
      flash[:notice] = "Invalid Permission to perform this operation"
      redirect_to :dashboard
    end
  end

  def destroy
    if @current_user.permissions.collect { |p| p.role }.find { |r| r.name == "Administrator" }
      if request.post? || request.delete?
        @user = User.find(params[:id])
        if @user.destroy
          flash[:notice] = "User Deleted"
        else
          flash[:error] = {
            :summary => "Failed to delete User",
            :failures => @user.errors.full_messages,
          }
        end
      end
    else
      flash[:notice] = "Invalid Permission to perform this operation"
    end
    redirect_to :dashboard
  end

  def section_id
    "loginpage"
  end
end
