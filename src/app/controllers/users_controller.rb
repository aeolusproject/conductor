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
  before_filter :require_user, :only => [:show, :edit, :update]
  before_filter :current_user, :only => [:new, :index]

  def new
    @user = User.new
  end

  def create
    require_privilege(Privilege::USER_MODIFY) unless current_user.nil?
    @user = User.new(params[:user])

    #TODO Set Quota Values to SelfService Settings Default Quota
    @user_quota = Quota.new
    @user.quota_id = @user_quota.id

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
    @users = User.all
  end
end