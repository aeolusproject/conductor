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

class CatalogsController < ApplicationController
  before_filter :require_user

  def index
    clear_breadcrumbs
    @catalogs = Catalog.list_for_user(current_user, Privilege::VIEW).apply_filters(:preset_filter_id => params[:catalogs_preset_filter], :search_filter => params[:catalogs_search])
    save_breadcrumb(catalogs_path(:viewstate => @viewstate ? @viewstate.id : nil))
    set_header
    set_admin_content_tabs 'catalogs'
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
    end
  end

  def new
    require_privilege(Privilege::CREATE, Catalog)
    @catalog = Catalog.new(params[:catalog]) # ...when should there be params on new?
    load_pools
  end

  def show
    @catalog = Catalog.find(params[:id])
    @catalog_entries = @catalog.catalog_entries.list_for_user(current_user, Privilege::VIEW).apply_filters(:preset_filter_id => params[:catalog_entries_preset_filter], :search_filter => params[:catalog_entries_search])
    require_privilege(Privilege::VIEW, @catalog)
    save_breadcrumb(catalogs_path(@catalog), @catalog.name)
    @header = [
      { :name => '', :sortable => false },
      { :name => t("catalog_entries.index.name"), :sort_attr => :name },
      { :name => t('catalog_entries.index.deployable_xml'), :sortable => false }
    ]
  end

  def create
    require_privilege(Privilege::CREATE, Catalog)
    @catalog = Catalog.new(params[:catalog])
    require_privilege(Privilege::MODIFY, @catalog.pool)
    if @catalog.save
      flash[:notice] = t('catalogs.flash.notice.created', :count => 1)
      redirect_to catalogs_path and return
    else
      load_pools
      render :new and return
    end
  end

  def edit
    @catalog = Catalog.find(params[:id])
    load_pools
    require_privilege(Privilege::MODIFY, @catalog)
  end

  def update
    @catalog = Catalog.find(params[:id])
    require_privilege(Privilege::MODIFY, @catalog)
    require_privilege(Privilege::MODIFY, @catalog.pool)

    if @catalog.update_attributes(params[:catalog])
      flash[:notice] = t('catalogs.flash.notice.updated', :count => 1)
      redirect_to catalogs_url
    else
      render :action => 'edit'
    end
  end

  def multi_destroy
    catalogs = Catalog.find(params[:catalogs_selected])
    catalogs.to_a.each do |catalog|
      require_privilege(Privilege::MODIFY, catalog)
      catalog.destroy
    end
    redirect_to catalogs_path, :notice => t("catalogs.flash.notice.deleted", :count => catalogs.count)
  end

  def destroy
    catalog = Catalog.find(params[:id])
    require_privilege(Privilege::MODIFY, catalog)
    catalog.destroy

    respond_to do |format|
      format.html { redirect_to catalogs_path, :notice => t("catalogs.flash.notice.deleted", :count => 1) }
    end
  end

  def filter
    original_path = Rails.application.routes.recognize_path(params[:current_path])
    original_params = Rack::Utils.parse_nested_query(URI.parse(params[:current_path]).query)
    redirect_to original_path.merge(original_params).merge("catalogs_preset_filter" => params[:catalogs_preset_filter], "catalogs_search" => params[:catalogs_search])
  end

  private

  def set_header
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t("catalogs.index.name"), :sort_attr => :name },
      { :name => t('pools.index.pool_name'), :sortable => false }
    ]
  end

  def load_pools
    @pools = Pool.list_for_user(current_user, Privilege::MODIFY)
  end
end
