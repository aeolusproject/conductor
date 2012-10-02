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

class CatalogsController < ApplicationController
  before_filter :require_user
  before_filter :transform_params_pool_id, :only => [:create, :update]

  def index
    @title = t('catalogs.catalogs')
    clear_breadcrumbs
    @catalogs = Catalog.
      apply_filters(:preset_filter_id => params[:catalogs_preset_filter],
                    :search_filter => params[:catalogs_search]).
      list_for_user(current_session, current_user, Privilege::VIEW)
    @can_create = Pool.list_for_user(current_session, current_user,
                                     Privilege::CREATE, Catalog).present?
    save_breadcrumb(catalogs_path(:viewstate => @viewstate ? @viewstate.id : nil))
    set_header
    set_admin_content_tabs 'catalogs'
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
      format.xml
    end
  end

  def new
    @catalog = Catalog.new(params[:catalog]) # ...when should there be params on new?
    load_pools
    require_privilege(Privilege::CREATE, Catalog, @pools.first)
    @title = t'catalogs.new.add_catalog'
  end

  def show
    @catalog = Catalog.find(params[:id])
    @title = @catalog.name
    load_deployables
    require_privilege(Privilege::VIEW, @catalog)
    save_breadcrumb(catalog_path(@catalog), @catalog.name)
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t("catalog_entries.index.name"), :sort_attr => :name },
      { :name => t('catalog_entries.index.deployable_xml'), :sortable => false }
    ]
  end

  def create
    @catalog = Catalog.new(params[:catalog])
    load_pools
    require_privilege(Privilege::CREATE, Catalog, @catalog.pool)

    respond_to do |format|
      if @catalog.save
        format.html do
          flash[:notice] = t('catalogs.flash.notice.created', :count => 1)
          redirect_to catalogs_path and return
        end
        format.xml do
          load_deployables
          render :show, :status => :ok
        end
      else
        format.html { render :new and return }
        format.xml  { render :template => 'api/validation_error',
                             :status => :bad_request,
                             :locals => { :errors => @catalog.errors }}
      end
    end
  end

  def edit
    @catalog = Catalog.find(params[:id])
    @title = t('catalogs.edit.edit_catalog')
    load_pools
    require_privilege(Privilege::MODIFY, @catalog)
  end

  def update
    @catalog = Catalog.find(params[:id])
    load_pools
    require_privilege(Privilege::MODIFY, @catalog)
    if params[:catalog][:pool_id] && @catalog.pool_id != params[:catalog][:pool_id]
      require_privilege(Privilege::CREATE, Catalog,
                        Pool.find(params[:catalog][:pool_id]))
    end

    respond_to do |format|
      if @catalog.update_attributes(params[:catalog])
        format.html do
          flash[:notice] = t('catalogs.flash.notice.updated', :count => 1)
          redirect_to catalogs_url
        end
        format.xml do
          load_deployables
          render :show
        end
      else
        format.html { render :action => 'edit' }
        format.xml  { render :template => 'api/validation_error',
                             :status => :bad_request,
                             :locals => { :errors => @catalog.errors }}
      end
    end
  end

  def multi_destroy
    deleted = []
    not_deleted = []
    not_deleted_perms = []
    catalogs = Catalog.find(params[:catalogs_selected])
    catalogs.to_a.each do |catalog|
      if check_privilege(Privilege::MODIFY, catalog)
        if catalog.destroy
          deleted << catalog.name
        else
          not_deleted << catalog.name
        end
      else
        not_deleted_perms << catalog.name
      end
    end
    flash[:notice] = t("catalogs.flash.notice.deleted", :count => deleted.count, :deleted => deleted.join(', ')) unless deleted.empty?
    unless not_deleted.empty? and not_deleted_perms.empty?
      flasherr = []
      flasherr = t("catalogs.flash.error.not_deleted", :count => not_deleted.count, :not_deleted => not_deleted.join(', ')) unless not_deleted.empty?
      flasherr = t("catalogs.flash.error.not_deleted_perms", :count => not_deleted_perms.count, :not_deleted => not_deleted_perms.join(', ')) unless not_deleted_perms.empty?
      flash[:error] = flasherr
    end
    redirect_to catalogs_path
  end

  def destroy
    catalog = Catalog.find(params[:id])
    require_privilege(Privilege::MODIFY, catalog)
    respond_to do |format|
      if catalog.destroy
        format.html do
          flash[:notice] = t("catalogs.flash.notice.one_deleted")
          redirect_to catalogs_path
        end
        format.xml { render :text => "<message>OK</message>\n", :status => :ok }
      else
        format.html do
          flash[:error] = t("catalogs.flash.error.one_not_deleted")
          redirect_to catalog_path(catalog)
        end
        format.xml  { render :template => 'api/validation_error',
                             :status => :bad_request,
                             :locals => { :errors => @catalog.errors }}
      end
    end
  end

  def filter
    redirect_to_original({"catalogs_preset_filter" => params[:catalogs_preset_filter], "catalogs_search" => params[:catalogs_search]})
  end

  private

  def transform_params_pool_id
    if params.has_key?(:catalog) && params[:catalog].is_a?(Hash) \
       && params[:catalog].has_key?(:pool) \
       && params[:catalog][:pool].has_key?(:id)

      pool_hash = params[:catalog].delete(:pool)
      params[:catalog][:pool_id] = pool_hash[:id]
    end
  end

  def set_header
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t("catalogs.index.name"), :sort_attr => :name },
      { :name => t('pools.index.pool_name'), :sortable => false }
    ]
  end

  def load_deployables
    @deployables = @catalog.deployables.
      list_for_user(current_session, current_user, Privilege::VIEW).
      apply_filters(:preset_filter_id => params[:deployables_preset_filter],
                    :search_filter => params[:deployables_search])
  end

  def load_pools
    if @catalog.pool_family
      @pools = @catalog.pool_family.pools.
        list_for_user(current_session, current_user, Privilege::CREATE, Catalog)
      @pools.unshift(@catalog.pool) unless @pools.include?(@catalog.pool)
    else
      @pools = Pool.list_for_user(current_session, current_user,
                                  Privilege::CREATE, Catalog)
    end
  end
end
