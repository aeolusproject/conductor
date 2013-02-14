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
    @title = _('Users')
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
    @title = _('New User')
    @user = User.new
    @user.quota = Quota.new_for_user
  end

  def create
    require_privilege(Privilege::MODIFY, User)
    @user = User.new(params[:user])
    @title = _('New User')
    @user.quota ||= Quota.new

    @registration = RegistrationService.new(@user)
    unless @registration.save
      render :action => 'new' and return
    end

    if current_user != @user
      flash[:notice] = _('User registered')
      redirect_to users_url
    else
      flash[:notice] = _('You have successfully registered.')
      redirect_to root_url
    end
  end

  def show
    @user = params[:id] ? User.find(params[:id]) : current_user
    require_privilege(Privilege::VIEW, User) unless current_user == @user
    @title = @user.name.present? ? @user.name : @user.username
    @quota_resources = @user.quota.quota_resources
    if current_user == user
      current_session.update_session_entities(current_user)
    end
    @user_groups = @user.all_groups
    @groups_header = [
      { :name => _('Name'), :sortable => false },
      { :name => _('Type'), :sortable => false },
    ]
    save_breadcrumb(user_path(@user), @user.name.present? ? @user.name : @user.username)
    @tab_captions = ['Properties']
    @details_tab = 'properties' # currently the only supported details tab
    add_profile_permissions_inline(@user.entity)
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
    @title = _('Edit User')
    @ldap_user = (SETTINGS_CONFIG[:auth][:strategy] == "ldap")
  end

  def update
    @title = _('Edit User')
    @user = params[:id] ? User.find(params[:id]) : current_user
    require_privilege(Privilege::MODIFY, User) unless @user == current_user
    # A user should not be able to edit their own quota:
    params[:user].delete(:quota_attributes) unless check_privilege(Privilege::MODIFY, User)

    if params[:commit] == "Reset"
      redirect_to edit_user_url(@user) and return
    end

    redirect_to root_url and return unless @user

    unless @user.update_attributes(params[:user])
      render :action => 'edit' and return
    else
      flash[:notice] = _('User updated')
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
            flash[:warning] = _('Cannot delete %s : You are logged in as this user') % "#{user.username}"
          else
            user.destroy
            deleted_users << user.username
          end
        end
      end

      unless deleted_users.empty?
        flash[:notice] =  "#{t('users.flash.notice.more_deleted', :count => deleted_users.length)} #{deleted_users.join(', ')}"
      end

    rescue => ex
      flash[:warning] = _('Cannot delete: %s') % ex.message
    end

    redirect_to users_url
  end

  def destroy
    require_privilege(Privilege::MODIFY, User)
    user = User.find(params[:id])
    if user == current_user
      flash[:warning] = "#{_('Cannot delete %s : You are logged in as this user') % "#{user.username}"}"
    else
      user.destroy
      flash[:notice] = _('User has been successfully deleted.')
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
    sort_order = params[:sort_by].nil? ? "username" : params[:sort_by]
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
      { :name => _('User ID'), :sortable => false },
      { :name => _('Last Name'), :sortable => false },
      { :name => _('First Name'), :sortable => false },
      { :name => _('Quota Used'), :class => 'center', :sortable => false },
      { :name => _('Quota Limit'), :class => 'center', :sortable => false },
      { :name => _('e-mail'), :sortable => false },
    ]
  end

end
