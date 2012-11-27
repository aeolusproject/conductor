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

class UserGroupsController < ApplicationController
  before_filter :require_user, :except => [:new, :create]

  def index
    require_privilege(Privilege::VIEW, User)
    @title = _("User Groups")
    clear_breadcrumbs
    save_breadcrumb(user_groups_path)
    set_admin_users_tabs 'user_groups'
    @params = params
    load_headers
    load_user_groups
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
    end
  end

  def show
    @user_group = UserGroup.find(params[:id])
    require_privilege(Privilege::VIEW, User)
    @title = @user_group.name
    save_breadcrumb(user_group_path(@user_group), @user_group.name)
    @tab_captions = ['Properties']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    @members = paginate_collection(@user_group.members.
                                   apply_filters(:preset_filter_id =>
                                                 params[:members_preset_filter],
                                                 :search_filter =>
                                                 params[:members_search]),
                                                 params[:page])
    add_profile_permissions_inline(@user_group.entity)
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

  def new
    require_privilege(Privilege::CREATE, User)
    @title = _("New User Group")
    @user_group = UserGroup.new
  end

  def create
    if params[:commit] == "Reset"
      redirect_to :action => 'new' and return
    end

    require_privilege(Privilege::MODIFY, User)
    @user_group = UserGroup.new(params[:user_group])

    respond_to do |format|
      if @user_group.save
        flash[:notice] = _("User Group added")
        format.html { redirect_to user_groups_path }
        format.json { render :json => @user_group, :status => :created }
      else
        format.html do
          @title = _("New User Group")
          render :new
        end
        format.js { render :partial => 'new' }
        format.json { render :json => @user_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @user_group = UserGroup.find(params[:id])
    require_privilege(Privilege::MODIFY, User)
    @title = _("Edit User Group")
  end

  def update
    @user_group = UserGroup.find(params[:id])
    require_privilege(Privilege::MODIFY, User)

    if params[:commit] == "Reset"
      redirect_to edit_user_group_url(@user_group) and return
    end

    redirect_to root_url and return unless @user_group

    unless @user_group.update_attributes(params[:user_group])
      @title = _("Edit User Group")
      render :action => 'edit' and return
    else
      flash[:notice] = _("User Group updated")
      redirect_to user_group_path(@user_group)
    end
  end

  def multi_destroy
    require_privilege(Privilege::MODIFY, User)
    deleted_user_groups = []

    begin
      UserGroup.transaction do
        UserGroup.find(params[:user_group_selected]).each do |user_group|
          if user_group.destroy
            deleted_user_groups << user_group.name
          end
        end
      end

      unless deleted_user_groups.empty?
        flash[:notice] =  "#{t('user_groups.flash.notice.more_deleted', :count => deleted_user_groups.length)} #{deleted_user_groups.join(', ')}"
      end

    rescue => ex
      flash[:warning] = _("Cannot delete: %s") % ex.message
    end

    redirect_to user_groups_url
  end

  def destroy
    require_privilege(Privilege::MODIFY, User)
    user_group = UserGroup.find(params[:id])
    if user_group.destroy
      flash[:notice] = _("User Group has been successfully deleted.")
    else
      flash[:notice] = _("Could not delete user group")
    end

    respond_to do |format|
      format.html { redirect_to user_groups_path }
    end
  end

  def add_members
    @user_group = UserGroup.find(params[:id])
    require_privilege(Privilege::MODIFY, User)

    unless @user_group.membership_source == UserGroup::MEMBERSHIP_SOURCE_LOCAL
      flash[:error] = _("Only locally-managed groups can be managed here.")
      redirect_to user_group_path(@user_group) and return
    end

    @users = paginate_collection(User.where('users.id not in (?)',
                                            @user_group.members.empty? ?
                                            0 : @user_group.members.map(&:id)),
                                 params[:page])

    added = []
    not_added = []

    if params[:members_selected].blank?
      flash[:error] = _("You must select at least one user to add.") if request.post?
    else
      User.find(params[:members_selected]).each do |member|
        if !@user_group.members.include?(member) and
            @user_group.members << member
          added << member.name
        else
          not_added << member.name
        end
      end
      unless added.empty?
        flash[:notice] = "#{_("These users have been added")}: #{added.join(', ')}"
      end
      unless not_added.empty?
        flash[:error] = "#{_("Could not add these users")}: #{not_added.join(', ')}"
      end
      respond_to do |format|
        format.html { redirect_to user_group_path(@user_group) }
      end
    end
  end

  def remove_members
    @user_group = UserGroup.find(params[:id])
    require_privilege(Privilege::MODIFY, User)

    unless @user_group.membership_source == UserGroup::MEMBERSHIP_SOURCE_LOCAL
      flash[:error] = _("Only locally-managed groups can be managed here.")
      redirect_to user_group_path(@user_group) and return
    end

    removed=[]
    not_removed=[]

    if params[:members_selected].blank?
      if request.post?
        flash[:error] = _("You must select at least one user to remove")
      end
    else
      User.find(params[:members_selected]).each do |member|
        if @user_group.members.delete member
          removed << member.name
        else
          not_removed << member.name
        end
      end
      unless removed.empty?
        flash[:notice] = "#{_("These users have been removed")}: #{removed.join(', ')}"
      end
      unless not_removed.empty?
        flash[:error] = "#{_("Could not remove these users")}: #{not_removed.join(', ')}"
      end
    end
    respond_to do |format|
      format.html { redirect_to user_group_path(@user_group) }
    end
  end

  def load_user_groups
    sort_order = params[:sort_by].nil? ? "name" : params[:sort_by]
    @user_groups = UserGroup.apply_filters(:preset_filter_id =>
                                           params[:user_groups_preset_filter],
                                           :search_filter =>
                                           params[:user_groups_search]).
      order(sort_order)
  end

  def load_headers
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => _("Name"), :sortable => false },
      { :name => _("Type"), :sortable => false },
    ]
  end

  def filter
    redirect_to_original({"user_groups_preset_filter" => params[:user_groups_preset_filter], "user_groups_search" => params[:user_groups_search]})
  end

  def filter_members
    redirect_to_original({"members_preset_filter" => params[:members_preset_filter], "members_search" => params[:members_search]})
  end

end
