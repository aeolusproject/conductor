#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

class UsersController < ApplicationController
  before_filter :require_user
  before_filter :load_users, :only => [:show]

  def index
    if !check_privilege(Privilege::VIEW, User)
      redirect_to account_url and return
    end
    @title = t'users.users'
    clear_breadcrumbs
    save_breadcrumb(users_path)
    set_admin_users_tabs 'users'
    @params = params
    load_headers
    load_users
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
    end
  end

  def new
    require_privilege(Privilege::CREATE, User)
    @title = t'users.new.new_user'
    @user = User.new
    @user.quota = Quota.new
  end

  def create
    if params[:commit] == "Reset"
      redirect_to :action => 'new' and return
    end

    require_privilege(Privilege::MODIFY, User)
    @user = User.new(params[:user])
    @user.quota ||= Quota.new

    @registration = RegistrationService.new(@user)
    unless @registration.save
      render :action => 'new' and return
    end

    if current_user != @user
      flash[:notice] = t"users.flash.notice.registered"
      redirect_to users_url
    else
      flash[:notice] = t"users.flash.notice.you_registred"
      redirect_to root_url
    end
  end

  def show
    @user = params[:id] ? User.find(params[:id]) : current_user
    require_privilege(Privilege::VIEW, User) unless current_user == @user
    @title = @user.name
    @quota_resources = @user.quota.quota_resources
    if current_user == user
      SessionEntity.update_session(current_session, current_user)
    end
    @user_groups = @user.all_groups
    @groups_header = [
      { :name => t('user_groups.index.name'), :sortable => false },
      { :name => t('user_groups.index.type'), :sortable => false },
    ]
    save_breadcrumb(user_path(@user), @user.name)
    @tab_captions = ['Properties']
    @details_tab = 'properties' # currently the only supported details tab
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
    @title = t'users.edit.edit_user'
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
      flash[:notice] = t"users.flash.notice.updated"
      redirect_to user_path(@user)
    end
  end

  def multi_destroy
    require_privilege(Privilege::MODIFY, User)
    deleted_users = []

    begin
      User.transaction do
        User.find(params[:user_selected]).each do |user|
          if user == current_user
            flash[:warning] = t('users.flash.warning.not_delete_same_user', :login => "#{user.login}")
          else
            user.destroy
            deleted_users << user.login
          end
        end
      end

      unless deleted_users.empty?
        flash[:notice] =  "#{t('users.flash.notice.more_deleted', :count => deleted_users.length)} #{deleted_users.join(', ')}"
      end

    rescue => ex
      flash[:warning] = t('users.flash.warning.not_delete', :reason => ex.message)
    end

    redirect_to users_url
  end

  def destroy
    require_privilege(Privilege::MODIFY, User)
    user = User.find(params[:id])
    if user == current_user
      flash[:warning] = "#{t('users.flash.warning.not_delete_same_user', :login => "#{user.login}")}"
    else
      user.destroy
      flash[:notice] = t"users.flash.notice.deleted"
    end

    respond_to do |format|
      format.html { redirect_to users_path }
    end
  end

  def filter
    redirect_to_original({"users_preset_filter" => params[:users_preset_filter], "users_search" => params[:users_search]})
  end

  protected

  def load_users
    @users = User.includes(:quota).apply_filters(:preset_filter_id => params[:users_preset_filter], :search_filter => params[:users_search])
    sort_order = params[:sort_by].nil? ? "login" : params[:sort_by]
    # TODO: (lmartinc) Optimize this sort! hell!
    if sort_order == "percentage_quota_used"
      @users.sort! {|x,y| y.quota.percentage_used <=> x.quota.percentage_used }
    elsif sort_order == "quota"
      @users.sort! {|x,y| (x.quota.maximum_running_instances and y.quota.maximum_running_instances) ? x.quota.maximum_running_instances <=> y.quota.maximum_running_instances : (x ? 1 : -1) }
    else
      @users = User.includes(:quota).apply_filters(:preset_filter_id => params[:users_preset_filter], :search_filter => params[:users_search]).order(sort_order)
    end
  end

  def load_headers
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t('users.index.user_id'), :sortable => false },
      { :name => t('users.index.last_name'), :sortable => false },
      { :name => t('users.index.first_name'), :sortable => false },
      { :name => t('quota_used'), :class => 'center', :sortable => false },
      { :name => t('users.index.quota_instances'), :class => 'center', :sortable => false },
      { :name => t('users.index.email'), :sortable => false },
    ]
  end

end
